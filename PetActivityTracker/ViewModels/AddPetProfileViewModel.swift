import Foundation
import Combine
import SwiftUI

@MainActor
class AddPetProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var breed = ""
    @Published var dateOfBirth = Date()
    @Published var photoData: Data?
    @Published var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            Task {
                if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
    }

    @Published var isCreating = false
    @Published var errorMessage: String?

    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
    }

    func addPet() async -> Bool {
        isCreating = true
        errorMessage = nil
        do {
            _ = try await firebaseService.createPet(
                name: name,
                breed: breed,
                dateOfBirth: dateOfBirth,
                photoData: photoData
            )
            isCreating = false
            return true
        } catch {
            errorMessage = "Error adding pet: \(error.localizedDescription)"
            isCreating = false
            return false
        }
    }
}
