import SwiftUI

struct DarentProfileView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var googleSignInService: GoogleSignInService

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    if let darent = firebaseService.darent {
                        Text(darent.displayName ?? "No display name")
                        Text(darent.email)
                    } else {
                        Text("Not logged in.")
                    }
                }

                Section {
                    Button(action: {
                        googleSignInService.signOut()
                    }) {
                        Text("Log Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("My Profile")
        }
    }
}

struct DarentProfileView_Previews: PreviewProvider {
    static var previews: some View {
        DarentProfileView()
            .environmentObject(FirebaseService())
            .environmentObject(GoogleSignInService())
    }
}
