//
//  OnboardingView.swift
//  DarentsApp
//
//  Created by Tia Burton on 7/2/25.
//

import SwiftUI
import PhotosUI

// MARK: - View Model
class OnboardingViewModel: ObservableObject {
    @Published var userProfile = UserProfile()
    @Published var petProfiles: [PetProfile] = [] // Start with an empty array
    @Published var isFinished: Bool = false

    // Computed property to determine whether onboarding has content
    var hasCompletedOnboarding: Bool {
        return !userProfile.name.isEmpty || !petProfiles.isEmpty
    }

    func addAnotherPet() {
        petProfiles.append(PetProfile())
    }

    func addNewPet(newPet: PetProfile) {
        petProfiles.append(newPet)
    }

    // Asynchronously load the image from the PhotosPickerItem
    func loadPetImage(for petId: UUID) {
        guard let index = petProfiles.firstIndex(where: { $0.id == petId }),
              let item = petProfiles[index].photosPickerItem else {
            return
        }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    // Update the UI on the main thread
                    DispatchQueue.main.async {
                        self.petProfiles[index].profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }

    // MARK: - Firestore Integration

    /// Saves the current onboarding data to Firestore using the FirebaseManager.
    func saveData(firebaseManager: FirebaseManager) {
        do {
            // 1. Convert the UserProfile object to a dictionary
            let userData = try JSONEncoder().encode(userProfile)
            guard let userDictionary = try JSONSerialization.jsonObject(with: userData, options: []) as? [String: Any] else {
                print("Error: Could not convert UserProfile to dictionary")
                return
            }

            // 2. Call the saveData function for the user
            firebaseManager.saveData(data: userDictionary, toCollection: "users")

            // 3. Loop through each pet in the petProfiles array and save them individually
            for pet in petProfiles {
                let petData = try JSONEncoder().encode(pet)
                guard let petDictionary = try JSONSerialization.jsonObject(with: petData, options: []) as? [String: Any] else {
                    print("Error: Could not convert PetProfile to dictionary")
                    return
                }

                // 4. Call the saveData function for each pet
                firebaseManager.saveData(data: petDictionary, toCollection: "pets")
            }

            // After saving, set the flag in UserDefaults and update the view model.
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                self.isFinished = true
            }

        } catch {
            print("Error during data encoding: \(error.localizedDescription)")
        }
    }

    /// Clears local data when a user signs out.
    func clearUserData() {
        self.userProfile = UserProfile()
        self.petProfiles = []
        self.isFinished = false
    }

    // MARK: - Load from Firestore

    /// Loads user + pet data asynchronously from Firestore into this view model.
    @MainActor
    func loadUserData(userId: String, firebaseManager: FirebaseManager) async {
        let (fetchedUser, fetchedPets) = await firebaseManager.fetchUserData(userId: userId)

        if let fetchedUser = fetchedUser {
            self.userProfile = fetchedUser
        }
        if let fetchedPets = fetchedPets {
            self.petProfiles = fetchedPets
        }

        // Use UserDefaults to check if onboarding has been completed.
        // This is more reliable than checking if the profile is empty,
        // as a user might not have filled out their profile completely.
        let hasOnboarded = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.isFinished = hasOnboarded || self.hasCompletedOnboarding
    }
}

// MARK: - Main App View (Post-Onboarding)
struct MainAppView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        NavigationView {
            if viewModel.petProfiles.isEmpty {
                Text("No pets added yet. Go to the 'Pet Details' section to add one!")
                    .foregroundColor(.secondary)
                    .padding()
                    .navigationTitle("My Pets")
            } else {
                List($viewModel.petProfiles) { $pet in
                    NavigationLink(destination: EditableDogProfileView(pet: $pet)) {
                        HStack {
                            pet.profileImage?
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                .clipped()

                            VStack(alignment: .leading) {
                                Text(pet.name.isEmpty ? "Unnamed Pet" : pet.name).font(.headline)
                                Text(pet.breeds.isEmpty ? "Unknown Breed" : pet.breeds).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("My Pets")
            }
        }
    }
}

// MARK: - Main Onboarding View (The Entry Point)
struct OnboardingHostView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        if viewModel.isFinished {
            MainAppView()
        } else {
            NavigationView {
                UserSignUpView()
            }
        }
    }
}

// MARK: - Step 1: User Sign Up
struct UserSignUpView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Welcome!")
                    .font(.largeTitle).fontWeight(.bold)
                Text("Let's create your profile first.")
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack(spacing: 12) {
                    TextField("Full Name", text: $viewModel.userProfile.name)
                    TextField("Email Address", text: $viewModel.userProfile.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone Number", text: $viewModel.userProfile.phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Age", text: $viewModel.userProfile.age)
                        .keyboardType(.numberPad)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                NavigationLink("Next", destination: LocationOptInView())
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .navigationTitle("Your Info")
    }
}

// MARK: - Step 2: Location Opt-In
struct LocationOptInView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Home Sweet Home")
                .font(.largeTitle).fontWeight(.bold)

            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("Optionally, add your home address to connect with local pet services.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("Home Address (Optional)", text: $viewModel.userProfile.homeAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            NavigationLink("Continue", destination: PetProfileCreationView())
                .buttonStyle(PrimaryButtonStyle())

            NavigationLink("Skip for now", destination: PetProfileCreationView())
                .padding(.top, 10)
        }
        .padding()
        .navigationTitle("Location")
    }
}

// MARK: - Step 3: Pet Profile Creation
struct PetProfileCreationView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var firebaseManager: FirebaseManager // Get the firebase manager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Tell Us About Your Pet(s)")
                    .font(.largeTitle).fontWeight(.bold)

                ForEach($viewModel.petProfiles) { $pet in
                    PetProfileFormSection(pet: $pet)
                }

                Button(action: viewModel.addAnotherPet) {
                    Label("Add Another Pet", systemImage: "plus.circle.fill")
                }
                .buttonStyle(SecondaryButtonStyle())

                // This button now saves data to Firestore
                Button("Finish & View Profile") {
                    viewModel.saveData(firebaseManager: firebaseManager)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Pet Details")
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Reusable Pet Form Section
struct PetProfileFormSection: View {
    @Binding var pet: PetProfile
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 12) {
            Group {
                Text(pet.name.isEmpty ? "New Pet Profile": pet.name)
                    .font(.title2).fontWeight(.semibold)

                PhotosPicker(selection: $pet.photosPickerItem, matching: .images) {
                    if let profileImage = pet.profileImage {
                        profileImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2))
                            .shadow(radius: 5)
                            .clipped()
                    } else {
                        Image(systemName: "pawprint.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .foregroundColor(.accentColor)
                            .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2))
                            .shadow(radius: 5)
                    }
                }
                .onChange(of: pet.photosPickerItem) { _ in
                    viewModel.loadPetImage(for: pet.id)
                }
            }

            Group {
                TextField("Pet's Name", text: $pet.name)
                TextField("Nickname (Optional)", text: $pet.nickname)
                TextField("Breed(s)", text: $pet.breeds)
                DatePicker("Birthday", selection: $pet.birthday, displayedComponents: .date)
                TextField("Weight (e.g., 75 lbs)", text: $pet.weight)
                TextField("Location", text: $pet.location) // New field for location
                TextField("Preferences", text: $pet.preferences) // New field for preferences
                TextField("Favorite Toy", text: $pet.favoriteToy)
                TextField("Favorite Snack", text: $pet.favoriteSnack)
                TextField("Favorite Game", text: $pet.favoriteGame)

                Text("Bio (Optional)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $pet.bio)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .textFieldStyle(PlainTextFieldStyle())
    }
}

// MARK: - Final, Editable Dog Profile View
struct EditableDogProfileView: View {
    @Binding var pet: PetProfile
    @State private var isEditing = false
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(alignment: .center, spacing: 20) {
                    pet.profileImage?
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 4))
                        .shadow(radius: 10)
                        .foregroundColor(.brown)
                        .clipped()

                    VStack(alignment: .leading) {
                        Text(pet.name.isEmpty ? "Unnamed Pet" : pet.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        if !pet.nickname.isEmpty {
                            Text("\"\(pet.nickname)\"")
                                .font(.headline)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 20)

                if !pet.bio.isEmpty {
                    Text(pet.bio)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(icon: "pawprint.fill", label: "Breed", value: pet.breeds.isEmpty ? "N/A" : pet.breeds)
                    Divider()
                    DetailRow(icon: "calendar", label: "Birthday", value: pet.birthday.formatted(date: .abbreviated, time: .omitted))
                    Divider()
                    DetailRow(icon: "scalemass.fill", label: "Weight", value: pet.weight.isEmpty ? "N/A" : pet.weight)
                    Divider()
                    DetailRow(icon: "mappin.and.ellipse", label: "Location", value: pet.location.isEmpty ? "N/A" : pet.location)
                    Divider()
                    DetailRow(icon: "star.fill", label: "Preferences", value: pet.preferences.isEmpty ? "N/A" : pet.preferences)
                    Divider()
                    Group {
                        DetailRow(icon: "heart.fill", label: "Favorite Toy", value: pet.favoriteToy.isEmpty ? "N/A" : pet.favoriteToy)
                        Divider()
                        DetailRow(icon: "fork.knife", label: "Favorite Snack", value: pet.favoriteSnack.isEmpty ? "N/A" : pet.favoriteSnack)
                        Divider()
                        DetailRow(icon: "gamecontroller.fill", label: "Favorite Game", value: pet.favoriteGame.isEmpty ? "N/A" : pet.favoriteGame)
                    }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationView {
                PetProfileFormSection(pet: $pet)
                    .navigationTitle("Edit Pet")
                    .navigationBarItems(trailing: Button("Done") {
                        isEditing = false
                    })
            }
        }
    }
}

// A helper view to create a consistent row format for each detail.
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 25, alignment: .center)
                .foregroundColor(.accentColor)
            Text(label)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut, value: configuration.isPressed)
    }
}

// MARK: - SwiftUI Preview
struct OnboardingHostView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingHostView()
            .environmentObject(OnboardingViewModel())
    }
}
