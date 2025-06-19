import Foundation
import FirebaseFirestore

struct FSPet: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var breed: String?
    var dateOfBirth: Timestamp? // Store date as Firestore Timestamp for consistency
    var photoURL: String? // URL of the photo in Firebase Storage

    var ownerUID: String // UID of the user who originally added this pet
    var householdID: String? // Optional: ID of the household this pet belongs to for sharing

    var createdTimestamp: Timestamp?
    var lastUpdatedTimestamp: Timestamp?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case breed
        case dateOfBirth
        case photoURL
        case ownerUID
        case householdID
        case createdTimestamp
        case lastUpdatedTimestamp
    }
}
