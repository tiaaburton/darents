//
//  AuthTests.swift
//  DarentsAppTests
//
//  Created by Jules on 9/25/25.
//

import XCTest
@testable import DarentsApp
import FirebaseAuth

class AuthTests: XCTestCase {

    var firebaseManager: FirebaseManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // In a real-world scenario, you would use a mock Firebase instance
        // or a separate Firebase project for testing. For this test, we
        // will use the live Firebase project, but only test failure cases
        // to avoid creating test users.
        firebaseManager = FirebaseManager()
    }

    override func tearDownWithError() throws {
        firebaseManager = nil
        try super.tearDownWithError()
    }

    func testSignInWithApple_WithInvalidToken_ThrowsError() async {
        // Arrange: Set a nonce and create an invalid token.
        firebaseManager.currentAppleSignInNonce = "test-nonce"
        let invalidToken = "this-is-not-a-valid-jwt"

        // Act & Assert: Attempt to sign in and expect an error.
        do {
            _ = try await firebaseManager.signInWithApple(idTokenString: invalidToken)
            // If this line is reached, the test has failed because no error was thrown.
            XCTFail("Expected signInWithApple to throw an error, but it succeeded.")
        } catch {
            // The test passes if an error is caught.
            // For a more specific test, we can check the error code.
            let nsError = error as NSError
            if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
                // We expect an invalid credential error from Firebase.
                XCTAssertEqual(authErrorCode, .invalidCredential, "Expected .invalidCredential error, but received \(authErrorCode)")
            } else {
                XCTFail("The error was not a FIRAuth error as expected.")
            }
        }
    }
}