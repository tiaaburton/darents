//
//  FirebaseManager.swift
//  DarentsApp
//
//  Created by Tia Burton on 9/12/25.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import GoogleSignIn
import AuthenticationServices
import CryptoKit

// This class is an ObservableObject, so SwiftUI views can subscribe to its changes.
class FirebaseManager: ObservableObject {
    
    static let shared = FirebaseManager()
    
    // @Published properties will notify any listening views when their values change.
    @Published var isAuthenticated: Bool = false
    @Published var currentUserId: String?
    @Published var errorMessage: String?
    
    let db = Firestore.firestore()
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    var currentAppleSignInNonce: String?
    
    init() {
        // When FirebaseManager is created, start listening for authentication changes.
        addAuthStateListener()
    }
    
    deinit {
        // When FirebaseManager is destroyed, remove the listener to prevent memory leaks.
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Household Management

    func createHousehold(name: String, completion: @escaping (Error?) -> Void) {
        guard let userId = currentUserId else {
            completion(HouseholdError.notAuthenticated)
            return
        }

        let newHouseholdRef = db.collection("households").document()
        let household = Household(id: newHouseholdRef.documentID, name: name, ownerId: userId, memberIds: [userId])

        let userRef = db.collection("users").document(userId)

        // Use a batch write to perform both operations atomically.
        let batch = db.batch()

        do {
            try batch.setData(from: household, forDocument: newHouseholdRef)
            batch.updateData(["householdId": newHouseholdRef.documentID], forDocument: userRef)

            batch.commit(completion: completion)
        } catch {
            completion(error)
        }
    }

    func joinHousehold(householdId: String, completion: @escaping (Error?) -> Void) {
        guard let userId = currentUserId else {
            completion(HouseholdError.notAuthenticated)
            return
        }

        let householdRef = db.collection("households").document(householdId)
        let userRef = db.collection("users").document(userId)

        let batch = db.batch()

        // Add the user to the household's members array and update the user's profile.
        batch.updateData(["memberIds": FieldValue.arrayUnion([userId])], forDocument: householdRef)
        batch.updateData(["householdId": householdId], forDocument: userRef)

        batch.commit(completion: completion)
    }

    enum HouseholdError: Error, LocalizedError {
        case notAuthenticated
        case householdNotFound

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "You must be logged in to manage a household."
            case .householdNotFound:
                return "The specified household could not be found."
            }
        }
    }
    
    func saveData(data: [String: Any], toCollection collection: String) {
            
        // Example: Saving data to a collection named 'users'
        db.collection(collection).addDocument(data: data) { error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
            } else {
                print("Document successfully added!")
            }
        }
    }

    /// Listens for changes to the user's sign-in state.
    private func addAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            // Use DispatchQueue.main.async to ensure UI updates happen on the main thread.
            DispatchQueue.main.async {
                if let user = user {
                    // If a user is logged in:
                    self?.isAuthenticated = true
                    self?.currentUserId = user.uid
                    self?.errorMessage = nil // Clear any previous error messages
                } else {
                    // If no user is logged in:
                    self?.isAuthenticated = false
                    self?.currentUserId = nil
                }
            }
        }
    }
    
    // MARK: - Email/Password Authentication
    
    /// Signs a user up with an email and password.
    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    // The authStateListener will handle the state change
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    /// Signs a user in with an email and password.
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    // The authStateListener will handle the state change
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - Google Authentication
    
    /// Signs in with Google using a presenting view controller.
    func signInWithGoogle(presenting viewController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(GoogleSignInError.missingClientID))
            return
        }
        
        // Configure Google Sign-In with the client ID.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the Google Sign-In authentication flow.
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] signInResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authentication = signInResult?.user,
                  let idToken = authentication.idToken else {
                completion(.failure(GoogleSignInError.authenticationFailed))
                return
            }
            
            // Create a Google credential from the ID token.
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                           accessToken: authentication.accessToken.tokenString)
            
            // Sign in to Firebase with the Google credential.
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                } else if let user = authResult?.user {
                    completion(.success(user))
                } else {
                    completion(.failure(GoogleSignInError.authenticationFailed))
                }
            }
        }
    }
    
    enum GoogleSignInError: Error, LocalizedError {
        case missingClientID
        case authenticationFailed
        
        var errorDescription: String? {
            switch self {
            case .missingClientID:
                return "Google Client ID is missing. Check your Firebase configuration."
            case .authenticationFailed:
                return "Google authentication failed. Please try again."
            }
        }
    }

    // MARK: - Apple Authentication
    
    /// Configures an Apple Sign-In request with a nonce.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        self.currentAppleSignInNonce = nonce // Store the nonce for later verification.
    }

    /// Signs the user into Firebase with an Apple credential.
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AppleSignInError.tokenSerializationFailed
        }
        
        // Call the internal, testable function with the extracted token string.
        return try await signInWithApple(idTokenString: idTokenString)
    }

    /// Internal function to sign in with an ID token string, allowing for testing.
    internal func signInWithApple(idTokenString: String) async throws -> User {
        guard let nonce = self.currentAppleSignInNonce else {
            fatalError("Invalid state: A nonce must be generated for Apple Sign-In.")
        }
        
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)

        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
        self.currentAppleSignInNonce = nil // Clear the nonce after a successful sign-in.
        return authResult.user
    }
    
    enum AppleSignInError: Error, LocalizedError {
        case authenticationFailed
        case missingIdentityToken
        case tokenSerializationFailed
        
        var errorDescription: String? {
            switch self {
            case .authenticationFailed:
                return "Apple authentication failed. Please try again."
            case .missingIdentityToken:
                return "Could not retrieve identity token from Apple credential."
            case .tokenSerializationFailed:
                return "Could not serialize Apple identity token."
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Generates a secure random string for use as a nonce in Apple Sign-In.
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYAZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    /// Creates a SHA256 hash of a string.
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Sign Out
    
    /// Signs the user out of Firebase Auth.
    func signOut() {
        do {
            try Auth.auth().signOut()
            errorMessage = nil
        } catch let signOutError as NSError {
            DispatchQueue.main.async {
                self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
            }
        }
    }
    
    // MARK: - Firestore Operations
    
    /// Saves a user profile and their pets to Firestore using a batch write.
    func saveUserData(userProfile: UserProfile, petProfiles: [PetProfile], completion: @escaping (Error?) -> Void) {
        guard let userId = currentUserId else {
            completion(NSError(domain: "com.darents.app", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."]))
            return
        }
        
        let userDocumentRef = db.collection("users").document(userId)
        let batch = db.batch()
        
        do {
            // Write the user profile to the batch
            try batch.setData(from: userProfile, forDocument: userDocumentRef)
            
            // Write each pet profile to a sub-collection in the batch
            for pet in petProfiles {
                let petDocumentRef = userDocumentRef.collection("pets").document(pet.id.uuidString)
                try batch.setData(from: pet, forDocument: petDocumentRef)
            }
            
            // Commit all writes at once
            batch.commit(completion: completion)
            
        } catch {
            completion(error)
        }
    }
    
    /// Updates the user's profile in Firestore.
    func updateUserProfile(_ userProfile: UserProfile, completion: @escaping (Error?) -> Void) {
        guard let userId = currentUserId else {
            completion(NSError(domain: "com.darents.app", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."]))
            return
        }

        let userDocumentRef = db.collection("users").document(userId)
        
        do {
            // Use setData with merge:true to update the document without overwriting other fields.
            try userDocumentRef.setData(from: userProfile, merge: true, completion: completion)
        } catch {
            completion(error)
        }
    }

    /// Fetches the user and pet profiles from Firestore asynchronously.
    func fetchUserData(userId: String) async -> (userProfile: UserProfile?, petProfiles: [PetProfile]?) {
        let userDocumentRef = db.collection("users").document(userId)

        do {
            // 1. Fetch User Profile. This will throw an error if the document doesn't exist.
            let userProfile = try await userDocumentRef.getDocument(as: UserProfile.self)

            // 2. If user profile is found, fetch their pets.
            let petsCollectionRef = userDocumentRef.collection("pets")
            let petQuerySnapshot = try await petsCollectionRef.getDocuments()

            let petProfiles = petQuerySnapshot.documents.compactMap { document -> PetProfile? in
                try? document.data(as: PetProfile.self)
            }

            return (userProfile, petProfiles)

        } catch {
            // If the user profile doesn't exist or another error occurs, return nil.
            // This is expected if it's a new user.
            print("Could not fetch user data (this is normal for a new user): \(error.localizedDescription)")
            return (nil, nil)
        }
    }
}
