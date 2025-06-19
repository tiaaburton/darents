import SwiftUI
import SwiftData

@Model
final class PetActivity {
    var id: String
    var timestamp: Date
    var activityType: String // e.g., "Walk", "Feed", "Play", "Medication"
    var notes: String?

    // Relationship: Each activity belongs to one pet
    @Relationship(inverse: \PetProfile.activities) var pet: PetProfile?

    init(id: String = UUID().uuidString, timestamp: Date = Date(), activityType: String = "", notes: String? = nil, pet: PetProfile? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.activityType = activityType
        self.notes = notes
        self.pet = pet
    }
}

// Extend PetProfile to include its activities
extension PetProfile {
    @Relationship(deleteRule: .cascade) var activities: [PetActivity]? = []
}
