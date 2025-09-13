import Foundation
import Combine

@MainActor
class CreateHouseholdViewModel: ObservableObject {
    @Published var name = ""
    @Published var isCreating = false
    @Published var errorMessage: String?

    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
    }

    func createHousehold() async -> Bool {
        isCreating = true
        errorMessage = nil
        do {
            _ = try await firebaseService.createHousehold(name: name)
            isCreating = false
            return true
        } catch {
            errorMessage = "Error creating household: \(error.localizedDescription)"
            isCreating = false
            return false
        }
    }
}
