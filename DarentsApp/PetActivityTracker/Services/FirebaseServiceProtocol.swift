import Foundation

protocol FirebaseServiceProtocol {
    // Define the methods and properties that your ViewModels need from FirebaseService
    // This is just an example, you should fill it with the actual methods from your FirebaseService
    func fetchHouseholds() async throws -> [Household]
    func createHousehold(name: String) async throws -> Household
    func fetchPets(for household: Household) async throws -> [PetProfile]
    func createPet(name: String, breed: String?, dateOfBirth: Date?, photoData: Data?) async throws -> PetProfile
    func fetchActivities(for pet: PetProfile) async throws -> [PetActivity]
    func createActivity(pet: PetProfile, type: String, notes: String?) async throws -> PetActivity

    var pets: FirestoreRepository<PetProfile> { get }
    var households: FirestoreRepository<Household> { get }
    var activities: FirestoreRepository<PetActivity> { get }
    var darents: FirestoreRepository<Darent> { get }
}
