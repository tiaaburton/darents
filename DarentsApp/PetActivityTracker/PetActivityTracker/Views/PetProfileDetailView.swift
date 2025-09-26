import SwiftUI

struct PetProfileDetailView: View {
    @StateObject private var viewModel: PetProfileDetailViewModel

    init(pet: PetProfile, firebaseService: FirebaseService) {
        _viewModel = StateObject(wrappedValue: PetProfileDetailViewModel(pet: pet, firebaseService: firebaseService))
    }

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                if let photoURL = viewModel.pet.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
                Text("Name: \(viewModel.pet.name)")
                if let breed = viewModel.pet.breed {
                    Text("Breed: \(breed)")
                }
                if let dob = viewModel.pet.dateOfBirth {
                    Text("Born: \(dob, style: .date)")
                }
            }

            Section(header: Text("Activities")) {
                if viewModel.isLoadingActivities {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                } else {
                    ForEach(viewModel.activities) { activity in
                        VStack(alignment: .leading) {
                            Text(activity.activityType)
                            Text(activity.timestamp.dateValue(), style: .time)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.pet.name)
        .task {
            await viewModel.fetchActivities()
        }
    }
}

struct PetProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PetProfileDetailView(pet: PetProfile(name: "Buddy"), firebaseService: FirebaseService())
    }
}
