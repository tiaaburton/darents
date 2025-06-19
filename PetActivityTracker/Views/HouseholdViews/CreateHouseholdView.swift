import SwiftUI

struct CreateHouseholdView: View {
    @EnvironmentObject var firebaseService: FirebaseService // Assuming FirebaseService is an EnvironmentObject
    @Environment(\.dismiss) var dismiss

    @State private var householdName: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Household Details")) {
                    TextField("Household Name", text: $householdName)
                        .autocapitalization(.words)
                }

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button("Create Household") {
                        createHousehold()
                    }
                    .disabled(householdName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Household")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func createHousehold() {
        isLoading = true
        errorMessage = nil
        let name = householdName.trimmingCharacters(in: .whitespacesAndNewlines)

        firebaseService.createHousehold(name: name) { result in
            isLoading = false
            switch result {
            case .success(let newHousehold):
                print("Successfully created household: \(newHousehold.householdName) with ID: \(newHousehold.id ?? "N/A")")
                // Optionally, you could pass this new household back or trigger a refresh
                dismiss()
            case .failure(let error):
                print("Error creating household: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct CreateHouseholdView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock FirebaseService for preview if necessary, or use a simple instance
        // This preview won't actually create a household but shows the UI.
        CreateHouseholdView()
            .environmentObject(FirebaseService()) // Basic FirebaseService for preview
    }
}
