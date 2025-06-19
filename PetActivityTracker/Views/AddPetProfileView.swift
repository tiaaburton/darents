import SwiftUI
// import SwiftData // No longer directly using SwiftData for saving here
import PhotosUI

struct AddPetProfileView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    // @Environment(\.modelContext) private var modelContext // Keep if still using SwiftData as local cache that gets populated from Firestore

    @State private var petName: String = ""
    @State private var petBreed: String = ""
    @State private var petDateOfBirth: Date = Date() // Consider making optional if not always known
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil

    @State private var userHouseholds: [FSHousehold] = []
    @State private var selectedHouseholdID: String? = nil // Store ID of selected household

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pet Details")) {
                    TextField("Name*", text: $petName)
                    TextField("Breed", text: $petBreed)
                    DatePicker("Date of Birth", selection: $petDateOfBirth, displayedComponents: .date)
                }

                Section(header: Text("Photo")) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Label("Select Pet Photo", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .onChange(of: selectedPhotoItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                            }
                        }
                    }
                    if selectedPhotoData != nil {
                        Button("Remove Photo", role: .destructive) {
                            selectedPhotoItem = nil
                            selectedPhotoData = nil
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                if !userHouseholds.isEmpty {
                    Section(header: Text("Share with Household (Optional)")) {
                        Picker("Select Household", selection: $selectedHouseholdID) {
                            Text("Don't share (Personal Pet)").tag(String?.none)
                            ForEach(userHouseholds) { household in
                                Text(household.householdName).tag(household.id as String?)
                            }
                        }
                    }
                }

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button("Add Pet") {
                        savePetProfileToFirestore()
                    }
                    .disabled(petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add New Pet")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fetchUserHouseholds()
            }
        }
    }

    private func fetchUserHouseholds() {
        isLoading = true // Can use a separate loading state for households if preferred
        firebaseService.fetchHouseholdsForCurrentUser { result in
            isLoading = false // Or the separate loading state
            switch result {
            case .success(let households):
                self.userHouseholds = households
            case .failure(let error):
                self.errorMessage = "Failed to load households: \(error.localizedDescription)"
            }
        }
    }

    private func savePetProfileToFirestore() {
        isLoading = true
        errorMessage = nil

        let name = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        let breed = petBreed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : petBreed.trimmingCharacters(in: .whitespacesAndNewlines)

        firebaseService.createPet(
            name: name,
            breed: breed,
            dateOfBirth: petDateOfBirth, // Consider if this should be optional
            photoData: selectedPhotoData,
            householdID: selectedHouseholdID
        ) { result in
            isLoading = false
            switch result {
            case .success(let newPet):
                print("Successfully added pet to Firestore: \(newPet.name) with ID: \(newPet.id ?? "N/A")")
                // Here, you might want to trigger a refresh in PetProfileListView
                // or sync this new FSPet to a local SwiftData cache if you're using one.
                // For now, just dismiss.
                dismiss()
            case .failure(let error):
                print("Error adding pet to Firestore: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct AddPetProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFirebase = FirebaseService()
        // Populate mockFirebase.userHouseholds for preview if needed
        // mockFirebase.currentFirebaseUser = ...

        return AddPetProfileView()
            .environmentObject(mockFirebase)
            // .modelContainer(for: PetProfile.self, inMemory: true) // If still using SwiftData cache
    }
}
