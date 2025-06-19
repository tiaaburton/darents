import SwiftUI

struct PetProfileListView: View {
    @EnvironmentObject var firebaseService: FirebaseService

    @State private var fsPets: [FSPet] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingAddPetSheet = false
    // @State private var petToEdit: FSPet? = nil // No longer presenting EditPetProfileView directly as sheet from here

    var body: some View {
        // NavigationView is already provided by the TabView in ContentView for each tab's root.
        // If this view could be pushed onto a navigation stack itself, then it might need its own NavigationView.
        // For TabView integration, direct NavigationView here might be redundant or cause nested NavViews.
        // Let's assume ContentView's NavigationView per tab is sufficient.
        // Update: Each tab in a TabView typically manages its own navigation stack. So, NavigationView here is correct.
        NavigationView {
            VStack {
                if isLoading && fsPets.isEmpty {
                    ProgressView("Loading your pets...").padding()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)").foregroundColor(.red).padding()
                } else if fsPets.isEmpty {
                    VStack {
                        Text("No pets found yet!").font(.headline)
                        Text("Tap the '+' button to add your first pet.").foregroundColor(.secondary)
                    }.padding()
                } else {
                    List {
                        ForEach(fsPets) { pet in
                            NavigationLink(destination: PetProfileDetailView(fsPet: pet).environmentObject(firebaseService)) {
                                HStack {
                                    if let photoURLString = pet.photoURL, let photoURL = URL(string: photoURLString) {
                                        AsyncImage(url: photoURL) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                                 .frame(width: 50, height: 50).clipShape(Circle())
                                        } placeholder: {
                                            ProgressView().frame(width: 50, height: 50)
                                        }
                                    } else {
                                        Image(systemName: "pawprint.circle.fill")
                                            .resizable().aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50).foregroundColor(.gray)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(pet.name).font(.headline)
                                        if let breed = pet.breed, !breed.isEmpty {
                                            Text(breed).font(.subheadline).foregroundColor(.gray)
                                        }
                                        if let householdId = pet.householdID, !householdId.isEmpty {
                                            Text("Shared").font(.caption).foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteFsPets)
                    }
                }
            }
            .navigationTitle("My Pets")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !fsPets.isEmpty && !isLoading { EditButton() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddPetSheet = true } label: {
                        Label("Add Pet", systemImage: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) { // Secondary leading item for refresh
                    if isLoading { ProgressView() } else {
                        Button { fetchPetsFromFirestore() } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }.disabled(isLoading)
                    }
                }
            }
            .sheet(isPresented: $showingAddPetSheet, onDismiss: fetchPetsFromFirestore) {
                AddPetProfileView().environmentObject(firebaseService)
            }
            // .sheet(item: $petToEdit, onDismiss: fetchPetsFromFirestore) { pet in
            //     EditPetProfileView(fsPet: pet).environmentObject(firebaseService)
            // } // Removed direct edit sheet, navigation to detail view handles editing.
            .onAppear {
                if firebaseService.currentFirebaseUser != nil && fsPets.isEmpty {
                    fetchPetsFromFirestore()
                }
            }
            .onChange(of: firebaseService.currentFirebaseUser) { newUser in
                if newUser != nil {
                    fetchPetsFromFirestore()
                } else {
                    fsPets = []
                    errorMessage = nil
                }
            }
        }
    }

    private func fetchPetsFromFirestore() {
        isLoading = true
        errorMessage = nil
        firebaseService.fetchPetsForCurrentUser { result in
            isLoading = false
            switch result {
            case .success(let pets):
                self.fsPets = pets.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteFsPets(offsets: IndexSet) {
        let petsToDelete = offsets.map { fsPets[$0] }
        isLoading = true

        let dispatchGroup = DispatchGroup()
        var deletionError: Error?

        for pet in petsToDelete {
            guard let petID = pet.id else { continue }
            dispatchGroup.enter()
            firebaseService.deletePet(petID: petID, photoURL: pet.photoURL) { error in
                if let error = error {
                    deletionError = error
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            isLoading = false
            if let error = deletionError {
                self.errorMessage = "Failed to delete one or more pets: \(error.localizedDescription)"
            }
            fetchPetsFromFirestore()
        }
    }
}

struct PetProfileListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFirebase = FirebaseService()
        return PetProfileListView()
            .environmentObject(mockFirebase)
    }
}
