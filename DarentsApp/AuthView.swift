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
    
    // Delegate to handle the Apple Sign-In flow.
    @State private var appleSignInDelegate = AppleSignInDelegate()
    
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
                            firebaseManager.signInWithApple(request: request, delegate: appleSignInDelegate) { result in
                                switch result {
                                case .success(_):
                                    print("Apple Sign-In successful!")
                                case .failure(let error):
                                    firebaseManager.errorMessage = error.localizedDescription
                                }
                            }
                        },
                        onCompletion: { result in
                            // The completion is handled by our delegate, not here directly.
                            // We do this to decouple the view from the delegate logic.
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
