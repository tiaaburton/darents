import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

/// A model representing a single activity performed for a pet.
struct PetActivity: Codable, Identifiable {
    /// The unique identifier for the activity.
    @DocumentID var id: String?

    /// The ID of the `PetProfile` this activity belongs to.
    var petID: String

    /// The ID of the `Darent` who recorded this activity.
    var darentID: String

    /// The timestamp of when the activity occurred.
    var timestamp: Timestamp

    /// The type of activity (e.g., "Walk", "Feed").
    var activityType: String

    /// Any notes about the activity.
    var notes: String?
}
