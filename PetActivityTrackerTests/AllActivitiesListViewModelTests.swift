import XCTest
@testable import PetActivityTracker

@MainActor
class AllActivitiesListViewModelTests: XCTestCase {

    var viewModel: AllActivitiesListViewModel!
    var mockFirebaseService: MockFirebaseService!

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        viewModel = AllActivitiesListViewModel(firebaseService: mockFirebaseService)
    }

    func testFetchAllActivities_Success() async {
        // Given
        let household = Household(name: "Test", darentIDs: [], petIDs: ["pet1"])
        let pet = PetProfile(id: "pet1", name: "Buddy")
        let activity = PetActivity(petID: "pet1", darentID: "darent1", timestamp: .init(), activityType: "Walk", notes: nil)
        mockFirebaseService.mockHouseholds = [household]
        mockFirebaseService.mockPets = [pet]
        mockFirebaseService.mockActivities = [activity]

        // When
        await viewModel.fetchAllActivities()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.activities.count, 1)
    }
}
