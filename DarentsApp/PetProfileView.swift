//
//  PetProfileView.swift
//  DarentsApp
//
//  Created by Tia Burton on 7/2/25.
//
// A view that displays a profile for a dog, including a picture,
// name, and key details. This view is designed to be easily
// integrated into a larger SwiftUI application.

import SwiftUI
import PhotosUI

// MARK: - Data Models
// These structs define the shape of our data for users and pets.
// Identifiable is crucial for using lists and ForEach loops.
// Codable allows easy conversion to/from Firestore documents.

struct UserProfile: Codable {
    var name: String = ""
    var age: String = "" // Using String for simplicity in TextField
    var phoneNumber: String = ""
    var email: String = ""
    var homeAddress: String = ""
    var householdId: String? = nil // The ID of the household the user belongs to
}

// PetProfile now conforms to Hashable and Codable
struct PetProfile: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String = ""
    var nickname: String = ""
    var birthday: Date = Date()
    var weight: String = ""
    var gotchaDay: Date? = nil
    var favoriteToy: String = ""
    var favoriteSnack: String = ""
    var favoriteGame: String = ""
    var breeds: String = ""
    var bio: String = ""
    var location: String = "" // New field for location
    var preferences: String = "" // New field for preferences
    
    // To handle the selected photo from the PhotosPicker
    // These properties are excluded from Codable conformance as Image and PhotosPickerItem are not Codable.
    // They are for UI state only.
    var profileImage: Image? = Image(systemName: "pawprint.circle.fill")
    var photosPickerItem: PhotosPickerItem? = nil

    // We must define CodingKeys to explicitly include/exclude properties from the Codable process.
    enum CodingKeys: String, CodingKey {
        case id, name, nickname, birthday, weight, gotchaDay, favoriteToy, favoriteSnack, favoriteGame, breeds, bio, location, preferences
    }

    // Implement hash(into:) to make PetProfile Hashable.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Implement == to make PetProfile Equatable (required by Hashable)
    static func == (lhs: PetProfile, rhs: PetProfile) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: SwiftUI View
struct PetProfileView: View {
    var body: some View {
        // The main container for the profile view, arranging elements
        // vertically. The whole view is embedded in a ScrollView to
        // ensure content is accessible on smaller screens.
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Profile Image
                // The main profile image for the dog. Using a system
                // image as a placeholder. In a real app, you would
                // replace this with an `AsyncImage` or a loaded `UIImage`.
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 4))
                    .padding(.top, 40)
                    .foregroundColor(.brown)

                // MARK: - Dog's Name
                // Displays the dog's name with a large, bold font.
                Text("Theo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                // MARK: - Dog's Bio
                // A short, descriptive bio for the dog.
                Text("Loves long walks on the beach and chasing squirrels. A very good boy who is always ready for a treat.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                // MARK: - Details Section
                // A styled section for key details about the dog.
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(icon: "pawprint.fill", label: "Breed", value: "Golden Retriever")
                    Divider()
                    DetailRow(icon: "calendar", label: "Age", value: "3 Years")
                    Divider()
                    DetailRow(icon: "scalemass.fill", label: "Weight", value: "75 lbs")
                    Divider()
                    DetailRow(icon: "heart.fill", label: "Favorite Toy", value: "Squeaky Tennis Ball")
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Pet Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - SwiftUI Preview
// This allows you to see the design in Xcode's preview canvas
// without having to run the entire app.
struct PetProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PetProfileView()
        }
    }
}
