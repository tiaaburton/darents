//
//  SettingsView.swift
//  DarentsApp
//
//  Created by Tia Burton on 7/2/25.
//

import SwiftUI

struct SettingsView: View {
    // Access the FirebaseManager to perform the sign-out action.
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    var body: some View {
        NavigationView {
            VStack {
                
                // A button that, when tapped, calls the signOut method on the firebaseManager.
                Button(action: {
                    firebaseManager.signOut()
                }) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 220)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
                
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(FirebaseManager()) // Provide a mock for preview
    }
}
