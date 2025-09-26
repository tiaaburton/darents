//
//  AuthView.swift
//  DarentsApp
//
//  Created by Tia Burton on 9/12/25.
//

import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    // State for the text fields and view mode
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true // true for Login, false for Sign Up
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // MARK: - Header
                    Text(isLoginMode ? "Welcome Back" : "Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    Text(isLoginMode ? "Please sign in to continue" : "Get started with your pet's journey")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // MARK: - Input Fields
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Error Message
                    if let errorMessage = firebaseManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // MARK: - Primary Action Button
                    Button(action: handleAction) {
                        Text(isLoginMode ? "Login" : "Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                    
                    // MARK: - Sign-In with Google Button
                    // This uses the built-in view from the GoogleSignInSwift package.
                    GoogleSignInButton(action: {
                        firebaseManager.signInWithGoogle(presenting: getRootViewController()) { result in
                            switch result {
                            case .success(_):
                                print("Google Sign-In successful!")
                                // The authStateListener will handle navigation
                            case .failure(let error):
                                firebaseManager.errorMessage = error.localizedDescription
                            }
                        }
                    })
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // MARK: - Sign-In with Apple Button
                    SignInWithAppleButton(
                        .continue,
                        onRequest: { request in
                            // This is called when the button is tapped.
                            // We configure the request with a nonce from the FirebaseManager.
                            firebaseManager.prepareAppleSignInRequest(request)
                        },
                        onCompletion: { result in
                            // The onCompletion closure gives us the result of the Apple Sign-In flow.
                            // We'll handle it in a separate async function.
                            Task {
                                await handleAppleSignIn(result: result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // MARK: - Toggle Button
                    Button(action: {
                        isLoginMode.toggle()
                        firebaseManager.errorMessage = nil // Clear error on mode switch
                    }) {
                        Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Login")
                            .font(.subheadline)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Login" : "Sign Up")
            .navigationBarHidden(true) // A cleaner look for an auth screen
        }
    }
    
    /// Calls the appropriate FirebaseManager function based on the current mode.
    private func handleAction() {
        if isLoginMode {
            firebaseManager.signIn(email: email, password: password)
        } else {
            firebaseManager.signUp(email: email, password: password)
        }
    }
    
    /// Handles the result of the Apple Sign-In flow.
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        do {
            switch result {
            case .success(let authorization):
                // Handle the successful authorization.
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    // Use a local error type, since FirebaseManager's is not accessible here.
                    throw NSError(domain: "com.darents.app", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not cast to Apple ID Credential."])
                }

                // Call the async sign-in function from the FirebaseManager.
                _ = try await firebaseManager.signInWithApple(credential: appleIDCredential)

            case .failure(let error):
                // Handle the failure from the Apple Sign-In flow.
                throw error
            }
        } catch {
            // Update the UI with any error messages.
            DispatchQueue.main.async {
                firebaseManager.errorMessage = error.localizedDescription
            }
        }
    }

    // A helper function to get the root view controller for presenting the Google Sign-In sheet.
    private func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }
        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        return root
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(FirebaseManager.shared) // Provide a mock manager for preview
    }
}