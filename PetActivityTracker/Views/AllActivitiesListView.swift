import SwiftUI
// import SwiftData // No longer using @Query

struct AllActivitiesListView: View {
    @EnvironmentObject var firebaseService: FirebaseService

    @State private var fsActivities: [FSActivity] = []
    @State private var fsPets: [FSPet] = [] // For pet names in list and for filter

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var selectedPetFilterID: String? = nil // Filter by a specific FSPet's ID
    @State private var showingAddActivitySheet = false


    var body: some View {
        NavigationView { // Each tab should have its own NavigationView for independent navigation stacks
            VStack {
                // Filter Picker
                if !fsPets.isEmpty {
                    HStack {
                        Text("Filter by Pet:")
                        Picker("Select Pet", selection: $selectedPetFilterID) {
                            Text("All Pets").tag(String?.none)
                            ForEach(fsPets) { pet in
                                Text(pet.name).tag(pet.id as String?)
                            }
                        }
                        .pickerStyle(.menu)

                        if selectedPetFilterID != nil {
                            Button { selectedPetFilterID = nil } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .padding(.leading, 5)
                        }
                    }
                    .padding(.horizontal)
                }

                if isLoading && fsActivities.isEmpty {
                    ProgressView("Loading activities...").padding()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)").foregroundColor(.red).padding()
                } else if fsActivities.isEmpty && selectedPetFilterID == nil {
                     Text("No activities recorded yet.").foregroundColor(.secondary).padding()
                } else if filteredActivities.isEmpty && selectedPetFilterID != nil {
                    Text("No activities found for the selected pet.").foregroundColor(.secondary).padding()
                }
                else {
                    List {
                        ForEach(filteredActivities) { activity in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(activity.activityType).font(.headline)
                                    Spacer()
                                    if let petName = petName(for: activity.petID) {
                                        Text(petName).font(.subheadline).foregroundColor(.secondary)
                                    } else {
                                        Text("Unknown Pet").font(.subheadline).foregroundColor(.orange)
                                    }
                                }
                                Text(activity.timestamp.dateValue(), style: .datetime).font(.caption).foregroundColor(.gray)
                                if let notes = activity.notes, !notes.isEmpty {
                                    Text("Notes: \(notes)").font(.caption).lineLimit(3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteFSActivities)
                    }
                }
            }
            .navigationTitle("All Activities")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !fsActivities.isEmpty && !isLoading { EditButton() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddActivitySheet = true } label: {
                        Label("Add Activity", systemImage: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) { // Secondary leading for refresh
                     if isLoading { ProgressView() } else {
                        Button { fetchAllData() } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }.disabled(isLoading)
                    }
                }
            }
            .sheet(isPresented: $showingAddActivitySheet, onDismiss: fetchAllData) {
                // AddPetActivityView needs to be able to select a pet if no pet is passed
                AddPetActivityView().environmentObject(firebaseService)
            }
            .onAppear {
                if firebaseService.currentFirebaseUser != nil && (fsActivities.isEmpty || fsPets.isEmpty) {
                    fetchAllData()
                }
            }
            .onChange(of: firebaseService.currentFirebaseUser) { newUser in
                if newUser != nil {
                    fetchAllData()
                } else {
                    fsActivities = []
                    fsPets = []
                    errorMessage = nil
                }
            }
        }
    }

    private var filteredActivities: [FSActivity] {
        if let petID = selectedPetFilterID {
            return fsActivities.filter { $0.petID == petID }
        } else {
            return fsActivities // Already sorted by service
        }
    }

    private func petName(for petID: String) -> String? {
        return fsPets.first { $0.id == petID }?.name
    }

    private func fetchAllData() {
        isLoading = true
        errorMessage = nil

        let group = DispatchGroup()
        var fetchedActivities: [FSActivity]?
        var fetchedPets: [FSPet]?
        var firstError: Error?

        group.enter()
        firebaseService.fetchAllActivitiesForUser { result in
            switch result {
            case .success(let activities): fetchedActivities = activities
            case .failure(let error): if firstError == nil { firstError = error }
            }
            group.leave()
        }

        group.enter()
        firebaseService.fetchPetsForCurrentUser { result in
            switch result {
            case .success(let pets): fetchedPets = pets
            case .failure(let error): if firstError == nil { firstError = error }
            }
            group.leave()
        }

        group.notify(queue: .main) {
            isLoading = false
            if let error = firstError {
                self.errorMessage = error.localizedDescription
            } else {
                self.fsActivities = fetchedActivities ?? []
                self.fsPets = (fetchedPets ?? []).sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            }
        }
    }

    private func deleteFSActivities(offsets: IndexSet) {
        let activitiesToDelete = offsets.map { filteredActivities[$0] }
        isLoading = true

        let dispatchGroup = DispatchGroup()
        var deletionError: Error?

        for activity in activitiesToDelete {
            guard let activityID = activity.id else { continue }
            dispatchGroup.enter()
            firebaseService.deleteActivity(activityID: activityID) { error in
                if let error = error { deletionError = error }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            isLoading = false
            if let error = deletionError {
                self.errorMessage = "Failed to delete one or more activities: \(error.localizedDescription)"
            }
            fetchAllData() // Refresh data
        }
    }
}

struct AllActivitiesListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFirebase = FirebaseService()
        // mockFirebase.currentFirebaseUser = ...
        // mockFirebase.fetchAllActivitiesForUser = ... (mock implementation)
        // mockFirebase.fetchPetsForCurrentUser = ... (mock implementation)
        return AllActivitiesListView()
            .environmentObject(mockFirebase)
    }
}
