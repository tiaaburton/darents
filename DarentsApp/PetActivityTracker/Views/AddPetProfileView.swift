import SwiftUI
import PhotosUI

struct AddPetProfileView: View {
    @StateObject private var viewModel: AddPetProfileViewModel
    @Environment(\.dismiss) var dismiss

    init(firebaseService: FirebaseService) {
        _viewModel = StateObject(wrappedValue: AddPetProfileViewModel(firebaseService: firebaseService))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pet Details")) {
                    TextField("Name", text: $viewModel.name)
                    TextField("Breed", text: $viewModel.breed)
                    DatePicker("Date of Birth", selection: $viewModel.dateOfBirth, displayedComponents: .date)
                }

                Section(header: Text("Photo")) {
                    PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                        if let photoData = viewModel.photoData, let image = UIImage(data: photoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            Label("Select Photo", systemImage: "photo")
                        }
                    }
                }

                if viewModel.isCreating {
                    ProgressView()
                } else {
                    Button("Add Pet") {
                        Task {
                            if await viewModel.addPet() {
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
            .navigationTitle("New Pet")
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

struct AddPetProfileView_Previews: PreviewProvider {
    static var previews: some View {
        AddPetProfileView(firebaseService: FirebaseService())
    }
}
