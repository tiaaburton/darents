import SwiftUI

struct HouseholdListView: View {
    @StateObject private var viewModel: HouseholdListViewModel

    @State private var showingCreateSheet = false

    init(firebaseService: FirebaseService) {
        _viewModel = StateObject(wrappedValue: HouseholdListViewModel(firebaseService: firebaseService))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading households...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else if viewModel.households.isEmpty {
                    Text("No households found.")
                        .foregroundColor(.secondary)
                } else {
                    List(viewModel.households) { household in
                        VStack(alignment: .leading) {
                            Text(household.name)
                                .font(.headline)
                            Text("Members: \(household.darentIDs.count)")
                                .font(.caption)
                            Text("Pets: \(household.petIDs.count)")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("My Households")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New") {
                        showingCreateSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateHouseholdView()
            }
            .task {
                await viewModel.fetchHouseholds()
            }
        }
    }
}

struct HouseholdListView_Previews: PreviewProvider {
    static var previews: some View {
        HouseholdListView(firebaseService: FirebaseService())
            .environmentObject(FirebaseService())
    }
}
