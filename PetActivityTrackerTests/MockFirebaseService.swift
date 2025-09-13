import Foundation
@testable import PetActivityTracker

class MockFirebaseService: FirebaseServiceProtocol {
    var mockHouseholds: [Household] = []
    var mockPets: [PetProfile] = []
    var mockActivities: [PetActivity] = []

    var error: Error?

    func fetchHouseholds() async throws -> [Household] {
        if let error = error { throw error }
        return mockHouseholds
    }

    func createHousehold(name: String) async throws -> Household {
        if let error = error { throw error }
        let newHousehold = Household(name: name, darentIDs: [], petIDs: [])
        mockHouseholds.append(newHousehold)
        return newHousehold
    }

    func fetchPets(for household: Household) async throws -> [PetProfile] {
        if let error = error { throw error }
        return mockPets.filter { household.petIDs.contains($0.id ?? "") }
    }

    func createPet(name: String, breed: String?, dateOfBirth: Date?, photoData: Data?) async throws -> PetProfile {
        if let error = error { throw error }
        let newPet = PetProfile(name: name, breed: breed, dateOfBirth: dateOfBirth)
        mockPets.append(newPet)
        return newPet
    }

    func fetchActivities(for pet: PetProfile) async throws -> [PetActivity] {
        if let error = error { throw error }
        return mockActivities.filter { $0.petID == pet.id }
    }

    func createActivity(pet: PetProfile, type: String, notes: String?) async throws -> PetActivity {
        if let error = error { throw error }
        let newActivity = PetActivity(petID: pet.id ?? "", darentID: "", timestamp: .init(), activityType: type, notes: notes)
        mockActivities.append(newActivity)
        return newActivity
    }

    // These are not part of the protocol, but are needed to satisfy the compiler
    // because the protocol has properties that are repositories.
    // In a real project, you might want to mock the repositories as well.
    var pets: FirestoreRepository<PetProfile> {
        return FirestoreRepository<PetProfile>(collectionName: "pets")
    }

    var households: FirestoreRepository<Household> {
        return FirestoreRepository<Household>(collectionName: "households")
    }

    var activities: FirestoreRepository<PetActivity> {
        return FirestoreRepository<PetActivity>(collectionName: "activities")
    }

    var darents: FirestoreRepository<Darent> {
        return FirestoreRepository<Darent>(collectionName: "darents")
    }
}
