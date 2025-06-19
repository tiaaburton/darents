import Foundation
import GoogleSignIn
import SwiftUI // Needed for @main actor if used for UI updates

class GoogleSignInService: ObservableObject {
    @Published var currentUserID: String?
    @Published var givenName: String?
    @Published var email: String?
    // Add other user properties you might need

    init() {
        // Attempt to restore previous sign-in state
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Error restoring previous sign in: \(error.localizedDescription)")
                return
            }
            self.updateUser(user: user)
        }
    }

    private func updateUser(user: GIDGoogleUser?) {
        guard let user = user else {
            self.currentUserID = nil
            self.givenName = nil
            self.email = nil
            return
        }

        self.currentUserID = user.userID
        self.givenName = user.profile?.givenName
        self.email = user.profile?.email
        // You can access other profile information like:
        // user.profile?.familyName
        // user.profile?.name
        // user.profile?.imageURL(withDimension: 320)
    }

    func signIn(presentingViewController: UIViewController? = nil) {
        guard let presentingVC = presentingViewController ?? UIApplication.shared.windows.first?.rootViewController else {
            print("Error: No presenting view controller found for Google Sign-In.")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
            guard let result = signInResult else {
                print("Error signing in: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.updateUser(user: result.user)
            print("Signed in as: \(result.user.profile?.name ?? "Unknown")")
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.updateUser(user: nil)
        print("User signed out.")
    }

    // This function needs to be called from your App Delegate or SwiftUI App life cycle
    static func handleURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
