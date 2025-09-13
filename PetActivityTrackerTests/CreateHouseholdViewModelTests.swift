import XCTest
@testable import PetActivityTracker

@MainActor
class CreateHouseholdViewModelTests: XCTestCase {

    var viewModel: CreateHouseholdViewModel!
    var mockFirebaseService: MockFirebaseService!

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        viewModel = CreateHouseholdViewModel(firebaseService: mockFirebaseService)
    }

    func testCreateHousehold_Success() async {
        // Given
        viewModel.name = "New Household"

        // When
        let success = await viewModel.createHousehold()

        // Then
        XCTAssertTrue(success)
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockFirebaseService.mockHouseholds.count, 1)
        XCTAssertEqual(mockFirebaseService.mockHouseholds.first?.name, "New Household")
    }

    func testCreateHousehold_Failure() async {
        // Given
        viewModel.name = "New Household"
        let error = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockFirebaseService.error = error

        // When
        let success = await viewModel.createHousehold()

        // Then
        XCTAssertFalse(success)
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(mockFirebaseService.mockHouseholds.isEmpty)
    }
}
