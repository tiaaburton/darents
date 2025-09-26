//
//  SettingsView.swift
//  DarentsApp
//
//  Created by Tia Burton on 7/2/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        NavigationView {
            Form {
                // Section for managing the user's own profile
                Section(header: Text("My Profile")) {
                    NavigationLink(destination: UserProfileView()) {
                        Text("Manage Profile")
                    }
                }
                
                // Section for household management
                Section(header: Text("Household")) {
                    NavigationLink(destination: HouseholdView()) {
                        Text("Manage Household")
                    }
                }
                
                // Section for the sign-out action
                Section {
                    Button(action: {
                        firebaseManager.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(FirebaseManager())
            .environmentObject(OnboardingViewModel())
    }
}