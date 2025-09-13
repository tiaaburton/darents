import SwiftUI
import PhotosUI

struct EditPetProfileView: View {
    @StateObject private var viewModel: EditPetProfileViewModel
    @Environment(\.dismiss) var dismiss

    init(pet: PetProfile, firebaseService: FirebaseService) {
        _viewModel = StateObject(wrappedValue: EditPetProfileViewModel(pet: pet, firebaseService: firebaseService))
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
                        } else if let photoURL = viewModel.pet.photoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit().frame(height: 200)
                            } placeholder: {
                                ProgressView().frame(height: 200)
                            }
                        } else {
                            Label("Select Photo", systemImage: "photo")
                        }
                    }
                }

                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        Task {
                            if await viewModel.save() {
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
            .navigationTitle("Edit Pet")
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

struct EditPetProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditPetProfileView(pet: PetProfile(name: "Buddy"), firebaseService: FirebaseService())
    }
}
