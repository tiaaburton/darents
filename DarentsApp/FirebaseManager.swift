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
    
    /// Signs in with Apple using an authorization request.
    func signInWithApple(request: ASAuthorizationAppleIDRequest, delegate: AppleSignInDelegate, completion: @escaping (Result<User, Error>) -> Void) {
        request.requestedScopes = [.fullName, .email]
        
        // Generate a cryptographically-secure nonce for the request.
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        self.currentAppleSignInNonce = nonce
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        
        delegate.onSignInComplete = { result in
            switch result {
            case .success(let credential):
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let user = authResult?.user {
                        completion(.success(user))
                    } else {
                        completion(.failure(AppleSignInError.authenticationFailed))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        controller.performRequests()
    }
    
    enum AppleSignInError: Error, LocalizedError {
        case authenticationFailed
        
        var errorDescription: String? {
            switch self {
            case .authenticationFailed:
                return "Apple authentication failed. Please try again."
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
    
    /// Fetches the user and pet profiles from Firestore.
    func fetchUserData(userId: String, completion: @escaping (UserProfile?, [PetProfile]?, Error?) -> Void) {
        let userDocumentRef = db.collection("users").document(userId)
        
        // 1. Fetch User Profile
        userDocumentRef.getDocument(as: UserProfile.self) { result in
            switch result {
            case .success(let userProfile):
                // 2. If user profile is found, fetch their pets
                let petsCollectionRef = userDocumentRef.collection("pets")
                petsCollectionRef.getDocuments { (querySnapshot, error) in
                    if let error = error {
                        completion(nil, nil, error)
                        return
                    }
                    
                    let petProfiles = querySnapshot?.documents.compactMap({ document -> PetProfile? in
                        try? document.data(as: PetProfile.self)
                    }) ?? []
                    
                    completion(userProfile, petProfiles, nil)
                }
                
            case .failure(let error):
                // Handle case where user profile might not exist or other error
                completion(nil, nil, error)
            }
        }
    }
}
