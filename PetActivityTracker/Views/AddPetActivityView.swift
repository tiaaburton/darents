import SwiftUI
// import SwiftData // Will not use @Query or modelContext for saving directly

struct AddPetActivityView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss

    // State for the form fields
    @State private var selectedPetID: String? // Store ID of the FSPet
    @State private var activityType: String = "Walk" // Default activity type
    @State private var activityDate: Date = Date()
    @State private var notes: String = ""

    // Pre-defined activity types
    let activityTypes = ["Walk", "Feed", "Play", "Medication", "Grooming", "Training", "Vet Visit", "Other"]

    // If a specific FSPet is passed (e.g. from PetProfileDetailView), pre-select it
    private var initialFsPet: FSPet?
    @State private var availableFsPets: [FSPet] = [] // For pet picker if initialFsPet is nil

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    // Initializer can accept an optional FSPet
    init(fsPet: FSPet? = nil) {
        self.initialFsPet = fsPet
        // Set initial selectedPetID if fsPet is provided
        // Note: @State vars must be initialized before self is available.
        // So, we use a temporary variable or do it in onAppear/task.
        // For simplicity, we'll handle it in onAppear.
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    // Pet Picker or Display
                    if let pet = initialFsPet {
                        LabeledContent("Pet:", value: pet.name)
                    } else if !availableFsPets.isEmpty {
                        Picker("Select Pet*", selection: $selectedPetID) {
                            Text("Select a Pet").tag(String?.none)
                            ForEach(availableFsPets) { petProfile in
                                Text(petProfile.name).tag(petProfile.id as String?)
                            }
                        }
                    } else if isLoading && initialFsPet == nil { // Show loading only if fetching pets for picker
                        ProgressView("Loading pets...")
                    }
                    else {
                        Text("No pets available. Please add a pet first from the 'My Pets' tab.")
                            .foregroundColor(.gray)
                    }

                    Picker("Activity Type*", selection: $activityType) {
                        ForEach(activityTypes, id: \.self) { type in Text(type) }
                    }
                    DatePicker("Date & Time*", selection: $activityDate)
                    TextField("Notes (Optional)", text: $notes, axis: .vertical).lineLimit(3...)
                }

                if isLoading { // General loading for save operation
                    ProgressView()
                } else {
                    Button("Record Activity") {
                        saveActivityToFirestore()
                    }
                    .disabled(currentPetID == nil || activityType.isEmpty)
                }

                if let errorMessage = errorMessage {
                    Section { Text("Error: \(errorMessage)").foregroundColor(.red) }
                }
            }
            .navigationTitle(initialFsPet != nil ? "Add Activity for \(initialFsPet!.name)" : "Add Pet Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
            }
            .task { // Use .task for async operations on appear
                if let pet = initialFsPet, let petID = pet.id {
                    _selectedPetID = State(initialValue: petID) // Initialize selectedPetID
                } else {
                    // Fetch available pets if no specific pet was passed
                    await fetchAvailablePets()
                }
            }
        }
    }

    // Computed property to get the Pet ID to use for saving
    private var currentPetID: String? {
        if let pet = initialFsPet {
            return pet.id
        }
        return selectedPetID
    }

    private func fetchAvailablePets() async {
        if firebaseService.currentFirebaseUser == nil {
            errorMessage = "You must be logged in to see pets."
            return
        }
        isLoading = true // For pets loading
        errorMessage = nil
        firebaseService.fetchPetsForCurrentUser { result in
            isLoading = false
            switch result {
            case .success(let pets):
                self.availableFsPets = pets
                // If only one pet available, auto-select it for the picker
                if self.availableFsPets.count == 1 && self.initialFsPet == nil {
                    self.selectedPetID = self.availableFsPets.first?.id
                }
            case .failure(let error):
                self.errorMessage = "Failed to load pets: \(error.localizedDescription)"
            }
        }
    }

    private func saveActivityToFirestore() {
        guard let petID = currentPetID else {
            errorMessage = "No pet selected for the activity."
            return
        }

        isLoading = true
        errorMessage = nil

        firebaseService.createActivity(
            petID: petID,
            activityType: activityType,
            timestamp: activityDate,
            notes: notes.isEmpty ? nil : notes
        ) { result in
            isLoading = false
            switch result {
            case .success(let newActivity):
                print("Successfully recorded activity to Firestore: \(newActivity.activityType) for pet \(newActivity.petID)")
                dismiss()
            case .failure(let error):
                self.errorMessage = "Failed to record activity: \(error.localizedDescription)"
            }
        }
    }
}

struct AddPetActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFirebase = FirebaseService()
        // Simulate a logged-in user for previews that fetch data
        // mockFirebase.currentFirebaseUser = ...

        // Preview for adding activity for a specific pet
        let samplePet = FSPet(id: "pet1", name: "Buddy Preview", ownerUID: "user1")
        AddPetActivityView(fsPet: samplePet)
            .environmentObject(mockFirebase)
            .previewDisplayName("For Specific Pet")

        // Preview for adding activity with pet selection
        // To make this preview more useful, mockFirebase.fetchPetsForCurrentUser could return sample FSPets
        AddPetActivityView()
            .environmentObject(mockFirebase)
            .previewDisplayName("With Pet Picker")
    }
}
