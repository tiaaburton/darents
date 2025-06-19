import SwiftUI
import PhotosUI // For PhotoPicker

struct EditPetProfileView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss

    // The FSPet object being edited
    var fsPet: FSPet

    // Local state for form fields, initialized from fsPet
    @State private var petName: String
    @State private var petBreed: String
    @State private var petDateOfBirth: Date
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var newSelectedPhotoData: Data? = nil // Data for a newly selected photo
    @State private var existingPhotoURL: String? // To display existing photo

    @State private var userHouseholds: [FSHousehold] = []
    @State private var selectedHouseholdID: String?

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showDeleteConfirmation: Bool = false


    // Initializer to populate state from the passed FSPet
    init(fsPet: FSPet) {
        self.fsPet = fsPet
        _petName = State(initialValue: fsPet.name)
        _petBreed = State(initialValue: fsPet.breed ?? "")
        _petDateOfBirth = State(initialValue: fsPet.dateOfBirth?.dateValue() ?? Date())
        _existingPhotoURL = State(initialValue: fsPet.photoURL)
        _selectedHouseholdID = State(initialValue: fsPet.householdID)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pet Details")) {
                    TextField("Name*", text: $petName)
                    TextField("Breed", text: $petBreed)
                    DatePicker("Date of Birth", selection: $petDateOfBirth, displayedComponents: .date)
                }

                Section(header: Text("Photo")) {
                    VStack {
                        if let newPhotoData = newSelectedPhotoData, let uiImage = UIImage(data: newPhotoData) {
                            Image(uiImage: uiImage) // Display newly selected photo
                                .resizable().scaledToFit().frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                        } else if let photoURLString = existingPhotoURL, let url = URL(string: photoURLString) {
                            AsyncImage(url: url) { image in // Display existing photo from URL
                                image.resizable().scaledToFit().frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                            } placeholder: {
                                ProgressView().frame(height: 200)
                            }
                        } else {
                            Label("Select or Change Photo", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Text(existingPhotoURL != nil || newSelectedPhotoData != nil ? "Change Photo" : "Select Photo")
                        }
                        .padding(.top, 5)
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    self.newSelectedPhotoData = data // Store new photo data
                                    // self.existingPhotoURL = nil // Clear existing URL if new photo is chosen, or let backend handle replacement
                                }
                            }
                        }

                        if newSelectedPhotoData != nil || existingPhotoURL != nil {
                             Button("Remove Current Photo", role: .destructive) {
                                selectedPhotoItem = nil
                                newSelectedPhotoData = nil
                                existingPhotoURL = nil // Signal that photo should be removed
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 5)
                        }
                    }
                }

                if !userHouseholds.isEmpty {
                    Section(header: Text("Share with Household")) {
                        Picker("Select Household", selection: $selectedHouseholdID) {
                            Text("Personal Pet (No Household)").tag(String?.none)
                            ForEach(userHouseholds) { household in
                                Text(household.householdName).tag(household.id as String?)
                            }
                        }
                    }
                }

                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button("Save Changes") {
                        updatePetInFirestore()
                    }
                    .disabled(petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section {
                    Button("Delete Pet Profile", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }

                if let errorMessage = errorMessage {
                    Section { Text("Error: \(errorMessage)").foregroundColor(.red) }
                }
            }
            .navigationTitle("Edit \(fsPet.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                fetchUserHouseholds()
            }
            .alert("Confirm Delete", isPresented: $showDeleteConfirmation) {
                Button("Delete \(fsPet.name)", role: .destructive) {
                    deletePetFromFirestore()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this pet profile? This action cannot be undone.")
            }
        }
    }

    private func fetchUserHouseholds() {
        // Assuming isLoading here is for the save/update operation.
        // If households loading needs its own indicator, add another @State var.
        firebaseService.fetchHouseholdsForCurrentUser { result in
            switch result {
            case .success(let households):
                self.userHouseholds = households
            case .failure(let error):
                self.errorMessage = "Failed to load households: \(error.localizedDescription)"
            }
        }
    }

    private func updatePetInFirestore() {
        guard let petID = fsPet.id else {
            errorMessage = "Pet ID is missing. Cannot update."
            return
        }
        isLoading = true
        errorMessage = nil

        let name = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        let breed = petBreed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : petBreed.trimmingCharacters(in: .whitespacesAndNewlines)

        // Determine if the photo should be removed entirely (no new photo, existingPhotoURL is now nil)
        let photoURLForUpdate = (newSelectedPhotoData == nil && existingPhotoURL == nil) ? nil : (existingPhotoURL ?? fsPet.photoURL)


        firebaseService.updatePet(
            petID: petID,
            name: name,
            breed: breed,
            dateOfBirth: petDateOfBirth,
            newPhotoData: newSelectedPhotoData, // Pass new data if any
            existingPhotoURL: photoURLForUpdate, // Pass current URL (might become nil if user removed it)
            householdID: selectedHouseholdID
        ) { result in
            isLoading = false
            switch result {
            case .success(let updatedPet):
                print("Successfully updated pet in Firestore: \(updatedPet.name)")
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deletePetFromFirestore() {
        guard let petID = fsPet.id else {
            errorMessage = "Pet ID is missing. Cannot delete."
            return
        }
        isLoading = true
        errorMessage = nil

        firebaseService.deletePet(petID: petID, photoURL: fsPet.photoURL) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to delete pet: \(error.localizedDescription)"
            } else {
                print("Pet \(petID) deleted successfully.")
                dismiss() // Dismiss the edit view
                // Need to also ensure the list view refreshes
            }
        }
    }
}

struct EditPetProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFirebase = FirebaseService()
        let samplePet = FSPet(id: "previewPet1", name: "Buddy Preview", breed: "Golden", ownerUID: "user123", householdID: "house1", createdTimestamp: .init())

        return EditPetProfileView(fsPet: samplePet)
            .environmentObject(mockFirebase)
    }
}
