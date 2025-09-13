import XCTest
@testable import PetActivityTracker

@MainActor
class PetProfileDetailViewModelTests: XCTestCase {

    var viewModel: PetProfileDetailViewModel!
    var mockFirebaseService: MockFirebaseService!
    let pet = PetProfile(id: "pet1", name: "Buddy")

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        viewModel = PetProfileDetailViewModel(pet: pet, firebaseService: mockFirebaseService)
    }

    func testFetchActivities_Success() async {
        // Given
        let activity = PetActivity(petID: "pet1", darentID: "darent1", timestamp: .init(), activityType: "Walk", notes: nil)
        mockFirebaseService.mockActivities = [activity]

        // When
        await viewModel.fetchActivities()

        // Then
        XCTAssertFalse(viewModel.isLoadingActivities)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.activities.count, 1)
        XCTAssertEqual(viewModel.activities.first?.activityType, "Walk")
    }

    func testFetchActivities_Failure() async {
        // Given
        let error = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockFirebaseService.error = error

        // When
        await viewModel.fetchActivities()

        // Then
        XCTAssertFalse(viewModel.isLoadingActivities)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.activities.isEmpty)
    }
}
