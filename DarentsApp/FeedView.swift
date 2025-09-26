//
//  FeedView.swift
//  DarentsApp
//
//  Created by Tia Burton on 9/12/25.
//

import SwiftUI

// This is a placeholder for your social feed.
// You can expand this later to fetch posts from other users from Firestore.

struct FeedView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "rectangle.stack.person.crop.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text("Community Feed")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("This feature is coming soon!")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .navigationTitle("Feed")
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
