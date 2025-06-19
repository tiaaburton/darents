import SwiftUI

struct HouseholdListView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var households: [FSHousehold] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading households...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if households.isEmpty {
                    Text("No households found. Create one to get started!")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(households) { household in
                            VStack(alignment: .leading) {
                                Text(household.householdName)
                                    .font(.headline)
                                Text("Owner: \(household.ownerUID == firebaseService.getCurrentUserUID() ? "You" : household.ownerUID)") // Simple owner display
                                    .font(.caption)
                                Text("Members: \(household.memberUIDs.count)")
                                    .font(.caption)
                            }
                            // TODO: NavigationLink to HouseholdDetailView
                        }
                    }
                }
            }
            .navigationTitle("My Households")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Label("New Household", systemImage: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button {
                           fetchHouseholds()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet, onDismiss: fetchHouseholds) { // Add onDismiss here
                CreateHouseholdView().environmentObject(firebaseService)
            }
            .onAppear {
                // Fetch households when the view appears if the user is logged in
                if firebaseService.currentFirebaseUser != nil && households.isEmpty {
                     fetchHouseholds()
                }
            }
            // Re-fetch if the Firebase user changes (e.g., after login)
            .onChange(of: firebaseService.currentFirebaseUser) { newUser in
                if newUser != nil {
                    fetchHouseholds()
                } else {
                    // User logged out, clear households
                    households = []
                    errorMessage = nil
                }
            }
        }
    }

    private func fetchHouseholds() {
        isLoading = true
        errorMessage = nil
        firebaseService.fetchHouseholdsForCurrentUser { result in
            isLoading = false
            switch result {
            case .success(let fetchedHouseholds):
                self.households = fetchedHouseholds
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                print("Error fetching households: \(error.localizedDescription)")
            }
        }
    }
}

struct HouseholdListView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock FirebaseService for preview
        let mockService = FirebaseService()
        // You could simulate a logged-in user for preview if needed
        // mockService.currentFirebaseUser = ... (some mock User object)
        // Or pre-populate mock households in the service for the preview

        return HouseholdListView()
            .environmentObject(mockService)
    }
}
