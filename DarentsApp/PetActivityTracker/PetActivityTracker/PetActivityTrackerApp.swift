import SwiftUI
import GoogleSignIn
import SwiftData
import FirebaseCore

@main
struct PetActivityTrackerApp: App {

    @StateObject var googleSignInService = GoogleSignInService()
    @StateObject var firebaseService = FirebaseService() // Initialize FirebaseService

    let modelContainer: ModelContainer = {
        let schema = Schema([
            PetProfile.self,
            PetActivity.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        FirebaseApp.configure()
        // Potentially configure Google Sign-In client ID here if needed
        // if let clientID = FirebaseApp.app()?.options.clientID {
        //    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        // }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(googleSignInService)
                .environmentObject(firebaseService) // Add FirebaseService to the environment
                .modelContainer(modelContainer)
                .onOpenURL { url in
                    GoogleSignInService.handleURL(url)
                }
        }
    }
}
