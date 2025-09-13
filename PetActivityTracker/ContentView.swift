import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct ContentView: View {
    @EnvironmentObject var googleSignInService: GoogleSignInService
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        Group {
            if googleSignInService.currentUserID != nil {
                TabView {
                    PetProfileListView()
                        .tabItem {
                            Label("My Pets", systemImage: "pawprint.fill")
                        }

                    AllActivitiesListView()
                        .tabItem {
                            Label("All Activities", systemImage: "list.bullet")
                        }

                    HouseholdListView()
                        .tabItem {
                            Label("Households", systemImage: "house.fill")
                        }

                    DarentProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
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
            .previewDisplayName("Signed Out State")

        // Preview for signed-in state
        let signedInGoogleService = GoogleSignInService()
        signedInGoogleService.currentUserID = "previewUser123"
        signedInGoogleService.givenName = "Preview User"

        return ContentView()
            .environmentObject(signedInGoogle-Service)
            .environmentObject(mockFirebaseService)
            .previewDisplayName("Signed In State")
    }
}
