import XCTest
@testable import PetActivityTracker

@MainActor
class HouseholdListViewModelTests: XCTestCase {

    var viewModel: HouseholdListViewModel!
    var mockFirebaseService: MockFirebaseService!

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        viewModel = HouseholdListViewModel(firebaseService: mockFirebaseService)
    }

    func testFetchHouseholds_Success() async {
        // Given
        let household = Household(name: "Test Household", darentIDs: ["darent1"], petIDs: ["pet1"])
        mockFirebaseService.mockHouseholds = [household]

        // When
        await viewModel.fetchHouseholds()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.households.count, 1)
        XCTAssertEqual(viewModel.households.first?.name, "Test Household")
    }

    func testFetchHouseholds_Failure() async {
        // Given
        let error = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockFirebaseService.error = error

        // When
        await viewModel.fetchHouseholds()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.households.isEmpty)
    }
}
