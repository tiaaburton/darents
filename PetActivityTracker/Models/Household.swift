import Foundation
import FirebaseFirestoreSwift

/// A model representing a household, which is a group of users and pets.
struct Household: Codable, Identifiable {
    /// The unique identifier for the household.
    @DocumentID var id: String?

    /// The name of the household.
    var name: String

    /// An array of user IDs (`Darent` IDs) that are members of this household.
    var darentIDs: [String]

    /// An array of pet IDs (`PetProfile` IDs) that belong to this household.
    var petIDs: [String]
}
