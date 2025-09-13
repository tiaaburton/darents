import Foundation
import Firebase
import FirebaseStorage
import Combine

/// A service class that provides a high-level interface for interacting with Firebase services.
///
/// This class is responsible for handling user authentication state, and for coordinating
/// data operations with Firestore and Firebase Storage. It uses a repository pattern
/// to abstract the direct Firestore queries.
@MainActor
class FirebaseService: ObservableObject, FirebaseServiceProtocol {

    // MARK: - Properties

    /// The currently authenticated Firebase user.
    @Published var currentUser: User?

    /// The application-specific user data for the current user.
    @Published var darent: Darent?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Repositories

    /// A repository for managing `Darent` documents in Firestore.
    let darents = FirestoreRepository<Darent>(collectionName: "darents")

    /// A repository for managing `PetProfile` documents in Firestore.
    let pets = FirestoreRepository<PetProfile>(collectionName: "pets")

    /// A repository for managing `Household` documents in Firestore.
    let households = FirestoreRepository<Household>(collectionName: "households")

    /// A repository for managing `PetActivity` documents in Firestore.
    let activities = FirestoreRepository<PetActivity>(collectionName: "activities")

    /// The Firebase Storage service.
    let storage = Storage.storage()

    // MARK: - Initialization

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            Task {
                await self?.loadDarentData()
            }
        }
    }

    // MARK: - User & Darent Management

    private func loadDarentData() async {
        guard let userId = currentUser?.uid else {
            self.darent = nil
            return
        }

        do {
            self.darent = try await darents.get(id: userId)
        } catch {
            if let email = currentUser?.email {
                let newDarent = Darent(id: userId, email: email, displayName: currentUser?.displayName)
                do {
                    self.darent = try await darents.create(newDarent)
                } catch {
                    print("Error creating darent data: \(error)")
                }
            }
        }
    }

    // MARK: - Pet Management

    /// Creates a new pet profile.
    /// - Parameters:
    ///   - name: The name of the pet.
    ///   - breed: The breed of the pet.
    ///   - dateOfBirth: The pet's date of birth.
    ///   - photoData: The image data for the pet's photo.
    /// - Returns: The newly created `PetProfile`.
    func createPet(name: String, breed: String?, dateOfBirth: Date?, photoData: Data?) async throws -> PetProfile {
        var newPet = PetProfile(name: name, breed: breed, dateOfBirth: dateOfBirth)

        if let photoData = photoData {
            let photoURL = try await uploadPhoto(photoData, path: "pet_photos/\(UUID().uuidString).jpg")
            newPet.photoURL = photoURL.absoluteString
        }

        return try await pets.create(newPet)
    }

    /// Fetches all pets for a given household.
    /// - Parameter household: The household to fetch pets for.
    /// - Returns: An array of `PetProfile`s.
    func fetchPets(for household: Household) async throws -> [PetProfile] {
        let allPets = try await pets.getAll()
        return allPets.filter { household.petIDs.contains($0.id ?? "") }
    }

    // MARK: - Household Management

    /// Creates a new household.
    /// - Parameter name: The name of the household.
    /// - Returns: The newly created `Household`.
    func createHousehold(name: String) async throws -> Household {
        guard let darentId = darent?.id else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
        }
        let newHousehold = Household(name: name, darentIDs: [darentId], petIDs: [])
        return try await households.create(newHousehold)
    }

    /// Fetches all households for the current user.
    /// - Returns: An array of `Household`s.
    func fetchHouseholds() async throws -> [Household] {
        guard let darentId = darent?.id else { return [] }
        let allHouseholds = try await households.getAll()
        return allHouseholds.filter { $0.darentIDs.contains(darentId) }
    }

    // MARK: - Activity Management

    /// Creates a new activity for a pet.
    /// - Parameters:
    ///   - pet: The pet the activity belongs to.
    ///   - type: The type of activity.
    ///   - notes: Any notes about the activity.
    /// - Returns: The newly created `PetActivity`.
    func createActivity(pet: PetProfile, type: String, notes: String?) async throws -> PetActivity {
        guard let petId = pet.id, let darentId = darent?.id else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid pet or user."])
        }
        let newActivity = PetActivity(petID: petId, darentID: darentId, timestamp: Timestamp(), activityType: type, notes: notes)
        return try await activities.create(newActivity)
    }

    /// Fetches all activities for a given pet.
    /// - Parameter pet: The pet to fetch activities for.
    /// - Returns: An array of `PetActivity`s.
    func fetchActivities(for pet: PetProfile) async throws -> [PetActivity] {
        guard let petId = pet.id else { return [] }
        let allActivities = try await activities.getAll()
        return allActivities.filter { $0.petID == petId }
    }

    // MARK: - Private Helpers

    private func uploadPhoto(_ data: Data, path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        _ = try await storageRef.putDataAsync(data)
        return try await storageRef.downloadURL()
    }
}
