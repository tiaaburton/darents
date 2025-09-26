import Foundation
import Combine
import SwiftUI

@MainActor
class EditPetProfileViewModel: ObservableObject {
    @Published var pet: PetProfile
    @Published var name: String
    @Published var breed: String
    @Published var dateOfBirth: Date
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

    @Published var isSaving = false
    @Published var errorMessage: String?

    private let firebaseService: FirebaseService

    init(pet: PetProfile, firebaseService: FirebaseService) {
        self.pet = pet
        self.name = pet.name
        self.breed = pet.breed ?? ""
        self.dateOfBirth = pet.dateOfBirth ?? Date()
        self.firebaseService = firebaseService
    }

    func save() async -> Bool {
        isSaving = true
        errorMessage = nil

        var updatedPet = pet
        updatedPet.name = name
        updatedPet.breed = breed
        updatedPet.dateOfBirth = dateOfBirth

        do {
            if let photoData = photoData {
                let photoURL = try await firebaseService.uploadPhoto(photoData, path: "pet_photos/\(pet.id ?? UUID().uuidString).jpg")
                updatedPet.photoURL = photoURL.absoluteString
            }

            try await firebaseService.pets.update(updatedPet)
            isSaving = false
            return true
        } catch {
            errorMessage = "Error saving pet: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
}
