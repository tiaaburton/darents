import Foundation
import FirebaseFirestoreSwift

/// A model representing a pet's profile.
struct PetProfile: Codable, Identifiable {
    /// The unique identifier for the pet profile, corresponding to the Firestore document ID.
    @DocumentID var id: String?

    /// The name of the pet.
    var name: String

    /// The breed of the pet.
    var breed: String?

    /// The pet's date of birth.
    var dateOfBirth: Date?

    /// The URL of the pet's photo in Firebase Storage.
    var photoURL: String?
}
