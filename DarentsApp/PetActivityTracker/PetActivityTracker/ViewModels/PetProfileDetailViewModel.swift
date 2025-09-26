import Foundation
import Combine

@MainActor
class PetProfileDetailViewModel: ObservableObject {
    @Published var pet: PetProfile
    @Published var activities: [PetActivity] = []
    @Published var isLoadingActivities = false
    @Published var errorMessage: String?

    private let firebaseService: FirebaseService

    init(pet: PetProfile, firebaseService: FirebaseService) {
        self.pet = pet
        self.firebaseService = firebaseService
    }

    func fetchActivities() async {
        isLoadingActivities = true
        errorMessage = nil
        do {
            self.activities = try await firebaseService.fetchActivities(for: pet)
        } catch {
            errorMessage = "Error fetching activities: \(error.localizedDescription)"
        }
        isLoadingActivities = false
    }
}
