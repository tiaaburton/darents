import XCTest
@testable import PetActivityTracker

@MainActor
class AddPetProfileViewModelTests: XCTestCase {

    var viewModel: AddPetProfileViewModel!
    var mockFirebaseService: MockFirebaseService!

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        viewModel = AddPetProfileViewModel(firebaseService: mockFirebaseService)
    }

    func testAddPet_Success() async {
        // Given
        viewModel.name = "Buddy"
        viewModel.breed = "Golden Retriever"

        // When
        let success = await viewModel.addPet()

        // Then
        XCTAssertTrue(success)
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockFirebaseService.mockPets.count, 1)
        XCTAssertEqual(mockFirebaseService.mockPets.first?.name, "Buddy")
    }

    func testAddPet_Failure() async {
        // Given
        viewModel.name = "Buddy"
        let error = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockFirebaseService.error = error

        // When
        let success = await viewModel.addPet()

        // Then
        XCTAssertFalse(success)
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(mockFirebaseService.mockPets.isEmpty)
    }
}
