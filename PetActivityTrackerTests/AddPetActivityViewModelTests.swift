import XCTest
@testable import PetActivityTracker

@MainActor
class AddPetActivityViewModelTests: XCTestCase {

    var viewModel: AddPetActivityViewModel!
    var mockFirebaseService: MockFirebaseService!
    let pet = PetProfile(id: "pet1", name: "Buddy")

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        viewModel = AddPetActivityViewModel(pet: pet, firebaseService: mockFirebaseService)
    }

    func testAddActivity_Success() async {
        // Given
        viewModel.activityType = "Walk"

        // When
        let success = await viewModel.addActivity()

        // Then
        XCTAssertTrue(success)
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockFirebaseService.mockActivities.count, 1)
    }
}
