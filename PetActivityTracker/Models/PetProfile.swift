import SwiftUI // For Image, if we store UI Image directly, though Data is better for model
import SwiftData

@Model
final class PetProfile {
    @Attribute(.unique) var id: String
    var name: String
    var breed: String?
    var dateOfBirth: Date?
    var photo: Data? // Store photo as Data

    init(id: String = UUID().uuidString, name: String = "", breed: String? = nil, dateOfBirth: Date? = nil, photo: Data? = nil) {
        self.id = id
        self.name = name
        self.breed = breed
        self.dateOfBirth = dateOfBirth
        self.photo = photo
    }
}
