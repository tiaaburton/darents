import Foundation
import FirebaseFirestore // For Timestamp and DocumentID

struct FSHousehold: Codable, Identifiable {
    @DocumentID var id: String? // Firestore document ID, populates automatically
    var householdName: String
    var ownerUID: String // UID of the user who owns/created the household
    var memberUIDs: [String] // Array of UIDs of users who are members
    var createdTimestamp: Timestamp? // Firestore Timestamp

    // CodingKeys can be useful for mapping Firestore field names if they differ
    enum CodingKeys: String, CodingKey {
        case id
        case householdName
        case ownerUID
        case memberUIDs
        case createdTimestamp
    }
}
