import Foundation
import Combine

@MainActor
class HouseholdListViewModel: ObservableObject {
    @Published var households: [Household] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
    }

    func fetchHouseholds() async {
        isLoading = true
        errorMessage = nil
        do {
            self.households = try await firebaseService.fetchHouseholds()
        } catch {
            errorMessage = "Error fetching households: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
