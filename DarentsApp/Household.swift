//
//  Household.swift
//  DarentsApp
//
//  Created by Jules on 9/25/25.
//

import Foundation
import FirebaseFirestoreSwift

struct Household: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var memberIds: [String]
}