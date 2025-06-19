import Foundation
import FirebaseFirestore

struct FSActivity: Codable, Identifiable {
    @DocumentID var id: String?
    var petID: String // ID of the FSPet this activity belongs to
    var userID: String // UID of the user who recorded this activity

    var timestamp: Timestamp // When the activity occurred
    var activityType: String
    var notes: String?

    var createdTimestamp: Timestamp? // When the record was created in Firestore

    enum CodingKeys: String, CodingKey {
        case id
        case petID
        case userID
        case timestamp
        case activityType
        case notes
        case createdTimestamp
    }
}
