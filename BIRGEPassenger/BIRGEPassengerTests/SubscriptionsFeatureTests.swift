import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class SubscriptionsFeatureTests: XCTestCase {
    func testPlanSelectionAndActivation() async {
        let store = TestStore(initialState: SubscriptionsFeature.State()) {
            SubscriptionsFeature()
        }

        await store.send(.planTapped("pro")) {
            $0.selectedPlanID = "pro"
        }
        await store.send(.activateSelectedTapped) {
            $0.currentPlanID = "pro"
            $0.selectedPlanID = nil
        }
    }

    func testCloseDetailClearsSelection() async {
        var state = SubscriptionsFeature.State()
        state.selectedPlanID = "standard"

        let store = TestStore(initialState: state) {
            SubscriptionsFeature()
        }

        await store.send(.closeDetailTapped) {
            $0.selectedPlanID = nil
        }
    }
}
