//
//  DarentsApp.swift
//  DarentsApp
//
//  Created by Tia Burton on 7/2/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices // For Apple Sign-In

// The AppDelegate is the standard way to configure Firebase when the app starts.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // This is required to handle the URL callback for Google Sign-In
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// A new class to handle the ASAuthorizationControllerDelegate for Apple Sign-In
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    var onSignInComplete: ((Result<AuthCredential, Error>) -> Void)?
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = FirebaseManager.shared.currentAppleSignInNonce else {
                fatalError("Invalid state: A nonce must be generated for Apple Sign-In.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token into string")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            onSignInComplete?(.success(credential))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onSignInComplete?(.failure(error))
    }
}


@main
struct DarentsApp: App {
    // Register the AppDelegate for Firebase setup.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Create the ViewModels as StateObjects at the top level of the app.
    // They will be the single source of truth for their respective data.
    @StateObject var onboardingViewModel = OnboardingViewModel()
    @StateObject var firebaseManager = FirebaseManager.shared

    var body: some Scene {
        WindowGroup {
            // This is the root view of the app.
            // It decides whether to show the authentication screen or the main app content.
            if firebaseManager.isAuthenticated {
                // If the user is authenticated, show the main TabView.
                MainTabView()
                    // Inject the view models into the environment so all child views can access them.
                    .environmentObject(onboardingViewModel)
                    .environmentObject(firebaseManager)
            } else {
                // Otherwise, show the authentication view.
                AuthView()
                    .environmentObject(firebaseManager)
            }
        }
    }
}

// A new struct to host the main TabView for the app.
// This allows a clean separation of the main app content from the login/onboarding flow.
struct MainTabView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @EnvironmentObject var firebaseManager: FirebaseManager

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "pawprint.fill")
                }

            OnboardingHostView()
                .tabItem {
                    Label("Pet Profile", systemImage: "pawprint.circle.fill")
                }
            
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "rectangle.stack.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        // When this view appears, if the user is authenticated, load their data.
        .onAppear {
            if firebaseManager.isAuthenticated, let userId = firebaseManager.currentUserId {
                onboardingViewModel.loadUserData(userId: userId, firebaseManager: firebaseManager)
            }
        }
        // This watches for changes in the authentication state (e.g., user logs out).
        .onChange(of: firebaseManager.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                // If the user logs out, clear all local user and pet data.
                onboardingViewModel.clearUserData()
            }
        }
    }
}
