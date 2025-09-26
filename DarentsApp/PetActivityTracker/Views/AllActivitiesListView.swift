import SwiftUI

struct AllActivitiesListView: View {
    @StateObject private var viewModel: AllActivitiesListViewModel

    init(firebaseService: FirebaseService) {
        _viewModel = StateObject(wrappedValue: AllActivitiesListViewModel(firebaseService: firebaseService))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading activities...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    List(viewModel.activities) { activity in
                        VStack(alignment: .leading) {
                            Text(activity.activityType)
                                .font(.headline)
                            Text("Pet ID: \(activity.petID)") // In a real app, you'd fetch the pet's name
                            Text(activity.timestamp.dateValue(), style: .date)
                        }
                    }
                }
            }
            .navigationTitle("All Activities")
            .task {
                await viewModel.fetchAllActivities()
            }
        }
    }
}

struct AllActivitiesListView_Previews: PreviewProvider {
    static var previews: some View {
        AllActivitiesListView(firebaseService: FirebaseService())
    }
}
