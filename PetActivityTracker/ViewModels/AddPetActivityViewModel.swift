import Foundation
import Combine

@MainActor
class AddPetActivityViewModel: ObservableObject {
    @Published var activityType = ""
    @Published var timestamp = Date()
    @Published var notes = ""

    @Published var isCreating = false
    @Published var errorMessage: String?

    private let pet: PetProfile
    private let firebaseService: FirebaseService

    init(pet: PetProfile, firebaseService: FirebaseService) {
        self.pet = pet
        self.firebaseService = firebaseService
    }

    func addActivity() async -> Bool {
        isCreating = true
        errorMessage = nil
        do {
            _ = try await firebaseService.createActivity(pet: pet, type: activityType, notes: notes)
            isCreating = false
            return true
        } catch {
            errorMessage = "Error adding activity: \(error.localizedDescription)"
            isCreating = false
            return false
        }
    }
}
