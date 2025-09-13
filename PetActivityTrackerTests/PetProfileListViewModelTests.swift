import XCTest
@testable import PetActivityTracker

@MainActor
class PetProfileListViewModelTests: XCTestCase {

    var viewModel: PetProfileListViewModel!
    var mockFirebaseService: MockFirebaseService!

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        viewModel = PetProfileListViewModel(firebaseService: mockFirebaseService)
    }

    func testFetchPets_Success() async {
        // Given
        let household = Household(name: "Test Household", darentIDs: ["darent1"], petIDs: ["pet1"])
        let pet = PetProfile(id: "pet1", name: "Buddy")
        mockFirebaseService.mockHouseholds = [household]
        mockFirebaseService.mockPets = [pet]

        // When
        await viewModel.fetchPets()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.pets.count, 1)
        XCTAssertEqual(viewModel.pets.first?.name, "Buddy")
    }

    func testFetchPets_Failure() async {
        // Given
        let error = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockFirebaseService.error = error

        // When
        await viewModel.fetchPets()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.pets.isEmpty)
    }

    func testFetchPets_LoadingState() async {
        // Given
        let expectation = XCTestExpectation(description: "isLoading state changes correctly")

        // When
        let task = Task {
            // Immediately after calling, isLoading should be true
            XCTAssertTrue(viewModel.isLoading)

            await viewModel.fetchPets()

            // After finishing, isLoading should be false
            XCTAssertFalse(viewModel.isLoading)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        task.cancel()
    }
}
