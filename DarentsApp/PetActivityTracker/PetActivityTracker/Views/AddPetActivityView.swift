import SwiftUI

struct AddPetActivityView: View {
    @StateObject private var viewModel: AddPetActivityViewModel
    @Environment(\.dismiss) var dismiss

    init(pet: PetProfile, firebaseService: FirebaseService) {
        _viewModel = StateObject(wrappedValue: AddPetActivityViewModel(pet: pet, firebaseService: firebaseService))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    TextField("Activity Type", text: $viewModel.activityType)
                    DatePicker("Date", selection: $viewModel.timestamp)
                    TextField("Notes", text: $viewModel.notes)
                }

                if viewModel.isCreating {
                    ProgressView()
                } else {
                    Button("Add Activity") {
                        Task {
                            if await viewModel.addActivity() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.activityType.isEmpty)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("New Activity")
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

struct AddPetActivityView_Previews: PreviewProvider {
    static var previews: some View {
        AddPetActivityView(pet: PetProfile(name: "Buddy"), firebaseService: FirebaseService())
    }
}
