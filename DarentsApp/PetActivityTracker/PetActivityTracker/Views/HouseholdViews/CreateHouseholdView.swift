import SwiftUI

struct CreateHouseholdView: View {
    @StateObject private var viewModel: CreateHouseholdViewModel
    @Environment(\.dismiss) var dismiss

    init(firebaseService: FirebaseService) {
        _viewModel = StateObject(wrappedValue: CreateHouseholdViewModel(firebaseService: firebaseService))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Household Name")) {
                    TextField("Name", text: $viewModel.name)
                }

                if viewModel.isCreating {
                    ProgressView()
                } else {
                    Button("Create") {
                        Task {
                            if await viewModel.createHousehold() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.name.isEmpty)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("New Household")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CreateHouseholdView_Previews: PreviewProvider {
    static var previews: some View {
        CreateHouseholdView(firebaseService: FirebaseService())
    }
}
