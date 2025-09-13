import XCTest
@testable import PetActivityTracker

@MainActor
class EditPetProfileViewModelTests: XCTestCase {

    var viewModel: EditPetProfileViewModel!
    var mockFirebaseService: MockFirebaseService!
    let pet = PetProfile(id: "pet1", name: "Buddy")

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        viewModel = EditPetProfileViewModel(pet: pet, firebaseService: mockFirebaseService)
    }

    func testSave_Success() async {
        // Given
        viewModel.name = "Buddy Junior"

        // When
        let success = await viewModel.save()

        // Then
        XCTAssertTrue(success)
        XCTAssertFalse(viewModel.isSaving)
        XCTAssertNil(viewModel.errorMessage)
        // In a real test, you would also check that the mockFirebaseService's update method was called with the correct data.
    }
}
