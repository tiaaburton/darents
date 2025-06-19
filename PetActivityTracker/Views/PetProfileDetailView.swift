import SwiftUI
// import SwiftData // No longer using @Bindable or SwiftData PetProfile directly

struct PetProfileDetailView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    var fsPet: FSPet // Now accepts an FSPet

    @State private var activities: [FSActivity] = []
    @State private var isLoadingActivities: Bool = false
    @State private var activityErrorMessage: String? = nil

    @State private var showingEditPetSheet = false
    @State private var showingAddActivitySheet = false

    // Computed property for pet's age or DOB string
    private var petAgeOrDOB: String {
        if let dobTimestamp = fsPet.dateOfBirth {
            let dob = dobTimestamp.dateValue()
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year, .month], from: dob, to: Date())
            if let years = ageComponents.year, years > 0 {
                return "\(years) year(s) old"
            } else if let months = ageComponents.month, months > 0 {
                return "\(months) month(s) old"
            } else {
                return "Less than a month old"
            }
        }
        return "N/A"
    }

    var body: some View {
        Form {
            Section(header: Text("Pet Information")) {
                if let photoURLString = fsPet.photoURL, let url = URL(string: photoURLString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
                        ProgressView().frame(height: 200)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 250, alignment: .center)
                } else {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable().scaledToFit().frame(height: 100).foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                LabeledContent("Name:", value: fsPet.name)
                if let breed = fsPet.breed, !breed.isEmpty {
                    LabeledContent("Breed:", value: breed)
                }
                LabeledContent("Age/DOB:", value: petAgeOrDOB)
                if let householdID = fsPet.householdID, !householdID.isEmpty {
                    // TODO: Fetch household name for display
                    LabeledContent("Household:", value: "ID: \(householdID.prefix(8))...")
                } else {
                    LabeledContent("Household:", value: "Personal Pet")
                }
            }

            Section(header: Text("Record Activity")) {
                Button {
                    showingAddActivitySheet = true
                } label: {
                    Label("Add New Activity for \(fsPet.name)", systemImage: "figure.walk")
                }
            }

            Section(header: Text("Recent Activities")) {
                if isLoadingActivities {
                    ProgressView("Loading activities...")
                } else if let errorMsg = activityErrorMessage {
                    Text("Error: \(errorMsg)").foregroundColor(.red)
                } else if activities.isEmpty {
                    Text("No activities recorded yet for \(fsPet.name).").foregroundColor(.gray)
                } else {
                    ForEach(activities.prefix(15)) { activity in // Show more activities
                        VStack(alignment: .leading) {
                            Text(activity.activityType).font(.headline)
                            Text(activity.timestamp.dateValue(), style: .datetime).font(.caption)
                            if let notes = activity.notes, !notes.isEmpty {
                                Text("Notes: \(notes)").font(.caption).lineLimit(3)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    // TODO: Add "View All Activities for this Pet" button if list is long
                }
            }
        }
        .navigationTitle(fsPet.name)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Edit Pet") { showingEditPetSheet = true }
            }
        }
        .sheet(isPresented: $showingEditPetSheet, onDismiss: {
            // Potentially refresh pet details if they could have changed,
            // though FSPet is a struct, so the view won't auto-update unless fsPet itself is changed.
            // This view might need to be re-instantiated or observe changes if live updates are needed post-edit.
        }) {
            EditPetProfileView(fsPet: fsPet).environmentObject(firebaseService)
        }
        .sheet(isPresented: $showingAddActivitySheet, onDismiss: fetchPetActivities) {
            AddPetActivityView(fsPet: fsPet).environmentObject(firebaseService)
        }
        .onAppear {
            fetchPetActivities()
        }
    }

    private func fetchPetActivities() {
        guard let petID = fsPet.id else {
            activityErrorMessage = "Pet ID is missing."
            return
        }
        isLoadingActivities = true
        activityErrorMessage = nil

        firebaseService.fetchActivities(for: petID) { result in
            isLoadingActivities = false
            switch result {
            case .success(let fetchedActivities):
                self.activities = fetchedActivities
            case .failure(let error):
                self.activityErrorMessage = error.localizedDescription
            }
        }
    }
}

struct PetProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFirebase = FirebaseService()
        let samplePet = FSPet(
            id: "pet1",
            name: "Rex Preview",
            breed: "German Shepherd",
            dateOfBirth: .init(date: Calendar.current.date(byAdding: .year, value: -3, to: Date())!),
            photoURL: nil, // Add a sample URL string here for photo preview
            ownerUID: "user123",
            householdID: "house1",
            createdTimestamp: .init()
        )
        // To preview activities, mockFirebase.fetchActivities would need to return sample data
        // for petID "pet1"

        return NavigationView {
            PetProfileDetailView(fsPet: samplePet)
                .environmentObject(mockFirebase)
        }
    }
}
