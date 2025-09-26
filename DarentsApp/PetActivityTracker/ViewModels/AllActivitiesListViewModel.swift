import Foundation
import Combine

@MainActor
class AllActivitiesListViewModel: ObservableObject {
    @Published var activities: [PetActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
    }

    func fetchAllActivities() async {
        isLoading = true
        errorMessage = nil
        do {
            let households = try await firebaseService.fetchHouseholds()
            let petIDs = households.flatMap { $0.petIDs }
            if !petIDs.isEmpty {
                // This is not ideal, as it fetches all activities for all pets.
                // A better approach for a real app would be to use a query with pagination.
                let allPets = try await firebaseService.pets.get(ids: Array(Set(petIDs)))
                var allActivities: [PetActivity] = []
                for pet in allPets {
                    allActivities.append(contentsOf: try await firebaseService.fetchActivities(for: pet))
                }
                self.activities = allActivities.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
            } else {
                self.activities = []
            }
        } catch {
            errorMessage = "Error fetching activities: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
