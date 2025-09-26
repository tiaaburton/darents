import Foundation
import FirebaseFirestoreSwift

/// A model representing a user of the app (a "darent" or dog parent).
struct Darent: Codable, Identifiable {
    /// The unique identifier for the user, corresponding to the Firebase Auth UID.
    @DocumentID var id: String?

    /// The user's email address.
    var email: String

    /// The user's display name.
    var displayName: String?
}
