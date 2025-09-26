import SwiftUI

struct PetProfileListView: View {
    @StateObject private var viewModel: PetProfileListViewModel

    @State private var showingAddPetSheet = false

    init(firebaseService: FirebaseService) {
        _viewModel = StateObject(wrappedValue: PetProfileListViewModel(firebaseService: firebaseService))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading && viewModel.pets.isEmpty {
                    ProgressView("Loading your pets...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.pets.isEmpty {
                    Text("No pets found. Add one!")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(viewModel.pets) { pet in
                            NavigationLink(destination: PetProfileDetailView(pet: pet)) {
                                Text(pet.name)
                            }
                        }
                        .onDelete(perform: viewModel.deletePet)
                    }
                }
            }
            .navigationTitle("My Pets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPetSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPetSheet) {
                AddPetProfileView()
            }
            .task {
                await viewModel.fetchPets()
            }
        }
    }
}

struct PetProfileListView_Previews: PreviewProvider {
    static var previews: some view {
        PetProfileListView(firebaseService: FirebaseService())
            .environmentObject(FirebaseService())
    }
}
