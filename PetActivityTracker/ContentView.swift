import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct ContentView: View {
    @EnvironmentObject var googleSignInService: GoogleSignInService
    @EnvironmentObject var firebaseService: FirebaseService // Add FirebaseService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if googleSignInService.currentUserID != nil {
                TabView {
                    PetProfileListView() // This will need to be adapted for Firestore later
                        .tabItem {
                            Label("My Pets", systemImage: "pawprint.fill")
                        }

                    AllActivitiesListView() // This will also need Firestore adaptation
                        .tabItem {
                            Label("All Activities", systemImage: "list.bullet")
                        }

                    HouseholdListView() // New Tab for Households
                        .tabItem {
                            Label("Households", systemImage: "house.fill")
                        }

                    // Optional: A settings/profile view for the signed-in user could also host household mgmt
                    // SettingsView()
                    //     .tabItem {
                    //         Label("Settings", systemImage: "gear")
                    //     }
                }
            } else {
                // User is not signed in, show sign-in view
                VStack {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.accentColor)
                        .padding(.bottom, 20)

                    Text("Welcome to Pet Activity Tracker!")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Please sign in to continue.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 30)

                    GIDSignInButton {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let rootViewController = windowScene.windows.first?.rootViewController else {
                            print("Could not find root view controller for sign-in.")
                            return
                        }
                        googleSignInService.signIn(presentingViewController: rootViewController)
                    }
                    .padding()

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let signedOutGoogleService = GoogleSignInService()
        let mockFirebaseService = FirebaseService() // Basic mock

        // Preview for signed-out state
        ContentView()
            .environmentObject(signedOutGoogleService)
            .environmentObject(mockFirebaseService)
            .modelContainer(for: PetProfile.self, PetActivity.self, inMemory: true)
            .previewDisplayName("Signed Out State")

        // Preview for signed-in state
        let signedInGoogleService = GoogleSignInService()
        signedInGoogleService.currentUserID = "previewUser123"
        signedInGoogleService.givenName = "Preview User"

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PetProfile.self, PetActivity.self, configurations: config)
        // Add sample data for previews if needed
        // let pet1 = PetProfile(name: "Buddy")
        // container.mainContext.insert(pet1)

        return ContentView()
            .environmentObject(signedInGoogleService)
            .environmentObject(mockFirebaseService) // Provide mock FirebaseService
            .modelContainer(container)
            .previewDisplayName("Signed In State")
    }
}
