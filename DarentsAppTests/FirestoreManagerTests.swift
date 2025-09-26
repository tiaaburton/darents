//
//  FirestoreManagerTests.swift
//  DarentsAppTests
//
//  Created by Jules on 9/25/25.
//

import XCTest
@testable import DarentsApp

class FirestoreManagerTests: XCTestCase {

    var firebaseManager: FirebaseManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        firebaseManager = FirebaseManager()
        // For these tests, we are not signing in, so currentUserId will be nil.
        // This allows us to test the failure paths of functions that require authentication.
    }

    override func tearDownWithError() throws {
        firebaseManager = nil
        try super.tearDownWithError()
    }

    func testUpdateUserProfile_WhenNotAuthenticated_Fails() {
        // Arrange
        let userProfile = UserProfile(name: "Test User")
        let expectation = self.expectation(description: "Update user profile fails")

        // Act
        firebaseManager.updateUserProfile(userProfile) { error in
            // Assert
            XCTAssertNotNil(error, "Expected an error but got nil")
            XCTAssertEqual((error as NSError).domain, "com.darents.app")
            XCTAssertEqual((error as NSError).code, 401)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateHousehold_WhenNotAuthenticated_Fails() {
        // Arrange
        let expectation = self.expectation(description: "Create household fails")

        // Act
        firebaseManager.createHousehold(name: "Test Household") { error in
            // Assert
            XCTAssertNotNil(error, "Expected an error but got nil")
            XCTAssertTrue(error is FirebaseManager.HouseholdError, "Expected HouseholdError")
            XCTAssertEqual(error as? FirebaseManager.HouseholdError, .notAuthenticated)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testJoinHousehold_WhenNotAuthenticated_Fails() {
        // Arrange
        let expectation = self.expectation(description: "Join household fails")

        // Act
        firebaseManager.joinHousehold(householdId: "some-id") { error in
            // Assert
            XCTAssertNotNil(error, "Expected an error but got nil")
            XCTAssertTrue(error is FirebaseManager.HouseholdError, "Expected HouseholdError")
            XCTAssertEqual(error as? FirebaseManager.HouseholdError, .notAuthenticated)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}