//
//  UserProfileView.swift
//  DarentsApp
//
//  Created by Jules on 9/25/25.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @EnvironmentObject var firebaseManager: FirebaseManager

    // State for showing alerts
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Full Name", text: $onboardingViewModel.userProfile.name)
                TextField("Email Address", text: $onboardingViewModel.userProfile.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Phone Number", text: $onboardingViewModel.userProfile.phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Age", text: $onboardingViewModel.userProfile.age)
                    .keyboardType(.numberPad)
            }

            Section(header: Text("Location")) {
                TextField("Home Address", text: $onboardingViewModel.userProfile.homeAddress)
            }

            Section {
                Button(action: saveProfile) {
                    Text("Save Changes")
                }
            }
        }
        .navigationTitle("Edit Profile")
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    /// Saves the user's profile to Firestore.
    private func saveProfile() {
        firebaseManager.updateUserProfile(onboardingViewModel.userProfile) { error in
            if let error = error {
                // Handle the error
                alertTitle = "Error"
                alertMessage = "There was a problem saving your profile: \(error.localizedDescription)"
            } else {
                // Handle the success
                alertTitle = "Success"
                alertMessage = "Your profile has been updated successfully."
            }
            showAlert = true
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserProfileView()
                .environmentObject(OnboardingViewModel())
                .environmentObject(FirebaseManager())
        }
    }
}