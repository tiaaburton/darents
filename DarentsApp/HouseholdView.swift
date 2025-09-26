//
//  HouseholdView.swift
//  DarentsApp
//
//  Created by Jules on 9/25/25.
//

import SwiftUI

struct HouseholdView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    @State private var householdName: String = ""
    @State private var householdToJoinId: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    var body: some View {
        Form {
            // This section will be shown if the user is not part of a household.
            if onboardingViewModel.userProfile.householdId == nil {
                Section(header: Text("Create a New Household")) {
                    TextField("Household Name", text: $householdName)
                    Button("Create Household") {
                        createHousehold()
                    }
                    // Disable the button if the name is empty.
                    .disabled(householdName.isEmpty)
                }

                Section(header: Text("Join an Existing Household")) {
                    TextField("Household ID", text: $householdToJoinId)
                        .autocapitalization(.none)
                    Button("Join Household") {
                        joinHousehold()
                    }
                    // Disable the button if the ID is empty.
                    .disabled(householdToJoinId.isEmpty)
                }
            } else {
                // This section will be shown if the user is already in a household.
                Section(header: Text("Your Household")) {
                    Text("You are already part of a household.")
                    // You could add features here to view household members or leave the household.
                }
            }
        }
        .navigationTitle("Household")
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    /// Calls the FirebaseManager to create a new household.
    private func createHousehold() {
        firebaseManager.createHousehold(name: householdName) { error in
            if let error = error {
                alertTitle = "Error"
                alertMessage = error.localizedDescription
            } else {
                alertTitle = "Success"
                alertMessage = "You have successfully created and joined the household!"
                // Refresh user data to get the new household ID
                if let userId = firebaseManager.currentUserId {
                    Task {
                        await onboardingViewModel.loadUserData(userId: userId, firebaseManager: firebaseManager)
                    }
                }
            }
            showAlert = true
        }
    }

    /// Calls the FirebaseManager to join an existing household.
    private func joinHousehold() {
        firebaseManager.joinHousehold(householdId: householdToJoinId) { error in
            if let error = error {
                alertTitle = "Error"
                alertMessage = error.localizedDescription
            } else {
                alertTitle = "Success"
                alertMessage = "You have successfully joined the household!"
                // Refresh user data to get the new household ID
                if let userId = firebaseManager.currentUserId {
                    Task {
                        await onboardingViewModel.loadUserData(userId: userId, firebaseManager: firebaseManager)
                    }
                }
            }
            showAlert = true
        }
    }
}

struct HouseholdView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HouseholdView()
                .environmentObject(FirebaseManager())
                .environmentObject(OnboardingViewModel())
        }
    }
}