import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage // For image storage
import Combine // For @Published properties if we make it an ObservableObject

// Define collection names as constants to avoid typos
enum FirestoreCollection: String {
    case households
    case pets
    case activities
    case users // For potential user-specific app data beyond Auth
}

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // Published properties for reactive UI updates if needed, e.g., for connection status or fetched data.
    // For now, methods will mostly return values or use completion handlers/async-await.
    @Published var currentFirebaseUser: Firebase.User? // Keep track of Firebase Auth user

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe Firebase Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.currentFirebaseUser = user
            if let user = user {
                print("FirebaseService: User signed in with UID: \(user.uid)")
                // Here you could trigger initial data fetches for the signed-in user
            } else {
                print("FirebaseService: User signed out.")
                // Clear any user-specific data
            }
        }
    }

    // MARK: - Helper Functions

    // Helper to get a reference to a collection
    private func collection(_ collectionName: FirestoreCollection) -> CollectionReference {
        return db.collection(collectionName.rawValue)
    }

    // Helper to get a reference to Firebase Storage
    private func storageReference(for path: String) -> StorageReference {
        return storage.reference().child(path)
    }

    // MARK: - User Management (Basic)

    func getCurrentUserUID() -> String? {
        return Auth.auth().currentUser?.uid
    }

    func getCurrentUserDisplayName() -> String? {
        return Auth.auth().currentUser?.displayName
    }

    // We can expand this with methods for households, pets, and activities later.
    // For example:
    // func createHousehold(name: String, completion: @escaping (Result<FSHousehold, Error>) -> Void) { ... }
    // func uploadPetImage(_ data: Data, petID: String, completion: @escaping (Result<URL, Error>) -> Void) { ... }

    // MARK: - Household Management

    func createHousehold(name: String, completion: @escaping (Result<FSHousehold, Error>) -> Void) {
        guard let userUID = getCurrentUserUID() else {
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        var newHousehold = FSHousehold(
            householdName: name,
            ownerUID: userUID,
            memberUIDs: [userUID], // Creator is automatically a member and owner
            createdTimestamp: Timestamp(date: Date())
        )

        do {
            // Add a new document with a generated ID
            let documentRef = try collection(.households).addDocument(from: newHousehold) { error in
                if let error = error {
                    completion(.failure(FirebaseServiceError.firestoreError(error)))
                } else {
                    // Successfully added, now fetch the document to get its ID and return it
                    documentRef.getDocument { snapshot, error in
                        if let error = error {
                            completion(.failure(FirebaseServiceError.firestoreError(error)))
                            return
                        }
                        guard let snapshot = snapshot, snapshot.exists else {
                            completion(.failure(FirebaseServiceError.documentNotFound))
                            return
                        }
                        do {
                            var createdHousehold = try snapshot.data(as: FSHousehold.self)
                            createdHousehold.id = snapshot.documentID // Ensure ID is set
                            completion(.success(createdHousehold))
                        } catch {
                            completion(.failure(FirebaseServiceError.dataDecodingError(error)))
                        }
                    }
                }
            }
        } catch {
            completion(.failure(FirebaseServiceError.dataEncodingError(error)))
        }
    }

    // Fetch all households where the current user is a member
    func fetchHouseholdsForCurrentUser(completion: @escaping (Result<[FSHousehold], Error>) -> Void) {
        guard let userUID = getCurrentUserUID() else {
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        collection(.households)
            .whereField("memberUIDs", arrayContains: userUID)
            .order(by: "createdTimestamp", descending: true) // Optional: order by creation time
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(FirebaseServiceError.firestoreError(error)))
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    completion(.success([])) // No documents found
                    return
                }

                let households = documents.compactMap { document -> FSHousehold? in
                    do {
                        var household = try document.data(as: FSHousehold.self)
                        household.id = document.documentID // Manually assign document ID
                        return household
                    } catch {
                        print("Error decoding household: \(error)")
                        return nil
                    }
                }
                completion(.success(households))
            }
    }

    // TODO: Add methods for:
    // - Inviting a user to a household (e.g., by email/UID)
    // - Accepting/Declining an invitation
    // - Leaving a household
    // - Removing a member from a household (owner only)
    // - Updating household details

    // MARK: - Pet Management

    // Uploads image data to Firebase Storage and returns the download URL
    func uploadPetPhoto(_ imageData: Data, petID: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard getCurrentUserUID() != nil else {
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        let photoRef = storageReference(for: "pet_photos/\(petID)/\(UUID().uuidString).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        photoRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(FirebaseServiceError.storageError(error)))
                return
            }
            photoRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(FirebaseServiceError.storageError(error)))
                    return
                }
                guard let downloadURL = url else {
                    completion(.failure(FirebaseServiceError.unknownError)) // Should not happen if putData succeeded
                    return
                }
                completion(.success(downloadURL))
            }
        }
    }

    func createPet(name: String, breed: String?, dateOfBirth: Date?, photoData: Data?, householdID: String?, completion: @escaping (Result<FSPet, Error>) -> Void) {
        guard let ownerUID = getCurrentUserUID() else {
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        // Generate a new ID for the pet for Firestore and for the photo path
        let newPetID = collection(.pets).document().documentID

        let group = DispatchGroup()
        var photoUploadError: Error?
        var finalPhotoURL: URL?

        if let photoData = photoData {
            group.enter()
            uploadPetPhoto(photoData, petID: newPetID) { result in
                switch result {
                case .success(let url):
                    finalPhotoURL = url
                case .failure(let error):
                    photoUploadError = error
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = photoUploadError {
                completion(.failure(error))
                return
            }

            var newPet = FSPet(
                id: newPetID, // Assign the generated ID
                name: name,
                breed: breed,
                dateOfBirth: dateOfBirth != nil ? Timestamp(date: dateOfBirth!) : nil,
                photoURL: finalPhotoURL?.absoluteString,
                ownerUID: ownerUID,
                householdID: householdID,
                createdTimestamp: Timestamp(date: Date()),
                lastUpdatedTimestamp: Timestamp(date: Date())
            )

            do {
                // Use the pre-generated ID (newPetID) for the document
                try self.collection(.pets).document(newPetID).setData(from: newPet) { error in
                    if let error = error {
                        completion(.failure(FirebaseServiceError.firestoreError(error)))
                    } else {
                        completion(.success(newPet))
                    }
                }
            } catch {
                completion(.failure(FirebaseServiceError.dataEncodingError(error)))
            }
        }
    }

    // Fetch pets owned by the current user OR pets belonging to households the user is part of.
    func fetchPetsForCurrentUser(completion: @escaping (Result<[FSPet], Error>) -> Void) {
        guard let userUID = getCurrentUserUID() else {
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        // First, get the list of household IDs the user is part of
        fetchHouseholdsForCurrentUser { [weak self] householdResult in
            guard let self = self else { return }

            var householdIDs: [String] = []
            switch householdResult {
            case .success(let households):
                householdIDs = households.compactMap { $0.id }
            case .failure(let error):
                // If fetching households fails, we might still proceed to fetch only owned pets,
                // or return the error. For now, let's return the error.
                completion(.failure(error))
                return
            }

            let group = DispatchGroup()
            var allFetchedPets: [FSPet] = []
            var fetchErrors: [Error] = []

            // Query 1: Pets directly owned by the user
            group.enter()
            self.collection(.pets)
                .whereField("ownerUID", isEqualTo: userUID)
                .getDocuments { snapshot, error in
                    if let error = error {
                        fetchErrors.append(error)
                    } else if let documents = snapshot?.documents {
                        allFetchedPets.append(contentsOf: documents.compactMap { doc -> FSPet? in
                            try? doc.data(as: FSPet.self)
                        })
                    }
                    group.leave()
                }

            // Query 2: Pets belonging to the user's households (if any)
            // Firestore 'in' queries are limited to 10 items in the array. If a user is in more than 10 households,
            // this needs to be broken into multiple queries. For simplicity, assuming <= 10 for now.
            // A more robust solution might involve a more complex data model or multiple fetches.
            if !householdIDs.isEmpty {
                group.enter()
                self.collection(.pets)
                    .whereField("householdID", in: householdIDs) // Fetches pets where householdID is one of the user's households
                    .getDocuments { snapshot, error in
                        if let error = error {
                            fetchErrors.append(error)
                        } else if let documents = snapshot?.documents {
                            allFetchedPets.append(contentsOf: documents.compactMap { doc -> FSPet? in
                                try? doc.data(as: FSPet.self)
                            })
                        }
                        group.leave()
                    }
            }

            group.notify(queue: .main) {
                if !fetchErrors.isEmpty {
                    // For simplicity, return the first error. Proper error handling might combine them.
                    completion(.failure(FirebaseServiceError.firestoreError(fetchErrors.first!)))
                } else {
                    // Remove duplicates (a pet could be owned AND in a household list)
                    let uniquePets = Array(Set(allFetchedPets.map { $0.id })).compactMap { id in
                        allFetchedPets.first { $0.id == id }
                    }
                    // Sort pets, e.g., by name or creation date
                    let sortedPets = uniquePets.sorted { ($0.createdTimestamp?.dateValue() ?? Date()) > ($1.createdTimestamp?.dateValue() ?? Date()) }
                    completion(.success(sortedPets))
                }
            }
        }
    }

    // TODO: Add methods for:
    // - Updating an FSPet (including photo if changed)
    // - Deleting an FSPet (and its photo from Storage)

    func updatePet(petID: String, name: String, breed: String?, dateOfBirth: Date?, newPhotoData: Data?, existingPhotoURL: String?, householdID: String?, completion: @escaping (Result<FSPet, Error>) -> Void) {
        guard getCurrentUserUID() != nil else {
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        let petDocumentRef = collection(.pets).document(petID)
        var updatedData: [String: Any] = [
            "name": name,
            "breed": breed ?? NSNull(), // Use NSNull for nil optional values
            "dateOfBirth": dateOfBirth != nil ? Timestamp(date: dateOfBirth!) : NSNull(),
            "householdID": householdID ?? NSNull(),
            "lastUpdatedTimestamp": Timestamp(date: Date())
        ]

        let photoHandlingGroup = DispatchGroup()
        var photoError: Error?
        var finalPhotoURLString = existingPhotoURL // Start with existing

        // If new photo data is provided, upload it
        if let newPhotoData = newPhotoData {
            photoHandlingGroup.enter()
            // If there was an old photo, and it's different, consider deleting it from storage.
            // For simplicity now, we're not deleting the old photo immediately upon changing it,
            // but this could be a future enhancement (e.g. if photoURL changes).
            // A more robust approach would involve checking if existingPhotoURL is different from the new one.

            uploadPetPhoto(newPhotoData, petID: petID) { result in
                switch result {
                case .success(let newURL):
                    finalPhotoURLString = newURL.absoluteString
                case .failure(let error):
                    photoError = error
                }
                photoHandlingGroup.leave()
            }
        }
        // If no new photo, but user wants to remove existing photo (e.g. newPhotoData is nil, selectedPhotoItem is nil in UI)
        // This case needs to be explicitly handled by the UI sending a clear signal, e.g. newPhotoData is nil AND a flag removeCurrentImage = true
        // For now, if newPhotoData is nil, we keep the existingPhotoURL or it becomes nil if existingPhotoURL was also nil.
        // If `newPhotoData` is `nil` and `existingPhotoURL` is not, `finalPhotoURLString` remains `existingPhotoURL`.
        // If `newPhotoData` is `nil` and `existingPhotoURL` is `nil`, `finalPhotoURLString` remains `nil`.

        photoHandlingGroup.notify(queue: .main) {
            if let error = photoError {
                completion(.failure(error))
                return
            }

            updatedData["photoURL"] = finalPhotoURLString ?? NSNull()

            petDocumentRef.updateData(updatedData) { error in
                if let error = error {
                    completion(.failure(FirebaseServiceError.firestoreError(error)))
                } else {
                    // Fetch the updated document to return it
                    petDocumentRef.getDocument { documentSnapshot, error in
                        if let error = error {
                            completion(.failure(FirebaseServiceError.firestoreError(error)))
                            return
                        }
                        guard let snapshot = documentSnapshot, snapshot.exists else {
                            completion(.failure(FirebaseServiceError.documentNotFound))
                            return
                        }
                        do {
                            let updatedPet = try snapshot.data(as: FSPet.self)
                            completion(.success(updatedPet))
                        } catch {
                            completion(.failure(FirebaseServiceError.dataDecodingError(error)))
                        }
                    }
                }
            }
        }
    }

    // Basic delete function for now. Does not delete photo from storage yet.
    func deletePet(petID: String, photoURL: String?, completion: @escaping (Error?) -> Void) {
        guard getCurrentUserUID() != nil else {
            completion(FirebaseServiceError.userNotAuthenticated)
            return
        }

        let petDocumentRef = collection(.pets).document(petID)
        petDocumentRef.delete { error in
            if let error = error {
                completion(FirebaseServiceError.firestoreError(error))
                return
            }

            // TODO: Delete photo from Firebase Storage if photoURL exists
            if let photoURLString = photoURL, let url = URL(string: photoURLString) {
                // Firebase Storage does not allow direct deletion by URL for security reasons.
                // You need the full path to the file in your bucket.
                // Assuming the path is extractable or known (e.g., from `uploadPetPhoto` logic)
                // For example, if path is "pet_photos/{petID}/{filename}.jpg"
                // let photoRef = self.storage.reference(forURL: photoURLString) // This might work if URL is a gs:// URL
                // For HTTP URLs, you need to parse the path or store it separately.
                // A simple way is to use the petID and a known filename pattern if you only store one photo per pet.
                // For now, skipping actual storage deletion.
                print("Pet document \(petID) deleted. Photo at \(photoURLString) should be deleted from Storage manually or via a Cloud Function.")
            }
            completion(nil)
        }
    }


    // MARK: - Activity Management

    func createActivity(petID: String, activityType: String, timestamp: Date, notes: String?, completion: @escaping (Result<FSActivity, Error>) -> Void) {
        guard let userUID = getCurrentUserUID() else {
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        var newActivity = FSActivity(
            petID: petID,
            userID: userUID,
            timestamp: Timestamp(date: timestamp),
            activityType: activityType,
            notes: notes,
            createdTimestamp: Timestamp(date: Date())
        )

        do {
            let documentRef = try collection(.activities).addDocument(from: newActivity) { error in
                if let error = error {
                    completion(.failure(FirebaseServiceError.firestoreError(error)))
                } else {
                    // Fetch the document to include its ID
                    documentRef.getDocument { snapshot, error in
                         if let error = error {
                            completion(.failure(FirebaseServiceError.firestoreError(error)))
                            return
                        }
                        guard let snapshot = snapshot, snapshot.exists else {
                            completion(.failure(FirebaseServiceError.documentNotFound))
                            return
                        }
                        do {
                            var createdActivity = try snapshot.data(as: FSActivity.self)
                            createdActivity.id = snapshot.documentID
                            completion(.success(createdActivity))
                        } catch {
                             completion(.failure(FirebaseServiceError.dataDecodingError(error)))
                        }
                    }
                }
            }
        } catch {
            completion(.failure(FirebaseServiceError.dataEncodingError(error)))
        }
    }

    // Fetch all activities for a specific pet ID, ordered by timestamp
    func fetchActivities(for petID: String, completion: @escaping (Result<[FSActivity], Error>) -> Void) {
        guard getCurrentUserUID() != nil else { // Or check if user has access to this petID based on ownership/household
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        collection(.activities)
            .whereField("petID", isEqualTo: petID)
            .order(by: "timestamp", descending: true)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(FirebaseServiceError.firestoreError(error)))
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let activities = documents.compactMap { document -> FSActivity? in
                    do {
                        var activity = try document.data(as: FSActivity.self)
                        activity.id = document.documentID
                        return activity
                    } catch {
                        print("Error decoding activity: \(error)")
                        return nil
                    }
                }
                completion(.success(activities))
            }
    }

    // TODO: Add methods for:
    // - Updating an FSActivity
    // - Deleting an FSActivity
    // - Fetching ALL activities for ALL pets a user has access to (for the AllActivitiesListView)

    // Fetches all activities for all pets the current user has access to.
    // This can be performance-intensive if there are many pets/activities.
    // Consider pagination or more targeted queries for production.
    func fetchAllActivitiesForUser(completion: @escaping (Result<[FSActivity], Error>) -> Void) {
        guard let userUID = getCurrentUserUID() else {
            completion(.failure(FirebaseServiceError.userNotAuthenticated))
            return
        }

        // 1. Fetch all pets the user has access to (owned or via household)
        fetchPetsForCurrentUser { [weak self] petResult in
            guard let self = self else { return }

            switch petResult {
            case .success(let fsPets):
                if fsPets.isEmpty {
                    completion(.success([])) // No pets, so no activities
                    return
                }

                let petIDs = fsPets.compactMap { $0.id }
                if petIDs.isEmpty {
                     completion(.success([]))
                     return
                }

                // 2. Fetch activities for these pet IDs.
                // Firestore 'in' queries are limited to 30 elements (previously 10).
                // If petIDs count > 30, we need to batch the queries.
                let group = DispatchGroup()
                var allActivities: [FSActivity] = []
                var fetchErrors: [Error] = []

                let chunks = petIDs.chunked(into: 30) // Helper to split into chunks of 30

                for chunkOfPetIDs in chunks {
                    group.enter()
                    self.collection(.activities)
                        .whereField("petID", in: chunkOfPetIDs)
                        // .order(by: "timestamp", descending: true) // Ordering across multiple 'in' values can be complex. Better to sort client-side.
                        .getDocuments { snapshot, error in
                            if let error = error {
                                fetchErrors.append(error)
                            } else if let documents = snapshot?.documents {
                                allActivities.append(contentsOf: documents.compactMap { doc -> FSActivity? in
                                    try? doc.data(as: FSActivity.self)
                                })
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    if !fetchErrors.isEmpty {
                        completion(.failure(FirebaseServiceError.firestoreError(fetchErrors.first!)))
                    } else {
                        // Sort activities by timestamp client-side
                        let sortedActivities = allActivities.sorted { ($0.timestamp.dateValue()) > ($1.timestamp.dateValue()) }
                        completion(.success(sortedActivities))
                    }
                }

            case .failure(let error):
                completion(.failure(error)) // Error fetching pets
            }
        }
    }

    func deleteActivity(activityID: String, completion: @escaping (Error?) -> Void) {
        guard getCurrentUserUID() != nil else { // Further checks might be needed to ensure user owns this activity or pet
            completion(FirebaseServiceError.userNotAuthenticated)
            return
        }
        collection(.activities).document(activityID).delete(completion: completion)
    }
}

// Helper extension for chunking arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}


// Example Error enum for more specific error handling
enum FirebaseServiceError: Error {
    case userNotAuthenticated
    case documentNotFound
    case dataEncodingError(Error)
    case dataDecodingError(Error)
    case firestoreError(Error)
    case storageError(Error)
    case unknownError
}
