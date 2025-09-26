import Foundation
import Combine

@MainActor
class PetProfileListViewModel: ObservableObject {
    @Published var pets: [PetProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
    }

    func fetchPets() async {
        isLoading = true
        errorMessage = nil
        do {
            let households = try await firebaseService.fetchHouseholds()
            let petIDs = households.flatMap { $0.petIDs }
            if !petIDs.isEmpty {
                self.pets = try await firebaseService.pets.get(ids: Array(Set(petIDs)))
            } else {
                self.pets = []
            }
        } catch {
            errorMessage = "Error fetching pets: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func deletePet(at offsets: IndexSet) {
        let petsToDelete = offsets.map { pets[$0] }
        Task {
            for pet in petsToDelete {
                do {
                    // Also delete photo from storage
                    if let photoURL = pet.photoURL {
                        let photoRef = firebaseService.storage.reference(forURL: photoURL)
                        try? await photoRef.delete()
                    }
                    try await firebaseService.pets.delete(pet)
                } catch {
                    errorMessage = "Failed to delete pet: \(error.localizedDescription)"
                }
            }
            await fetchPets()
        }
    }
}
