import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class OnboardingFeatureTests: XCTestCase {
    func testNextWalksThroughCommuteSetupBeforeFinishing() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.nextTapped) {
            $0.currentPage = 1
        }
        await store.send(.nextTapped) {
            $0.currentPage = 2
        }
        await store.send(.nextTapped) {
            $0.currentPage = 3
        }
        await store.send(.nextTapped) {
            $0.currentPage = 4
        }
        await store.send(.nextTapped) {
            $0.currentPage = 5
        }
        await store.send(.nextTapped) {
            $0.currentPage = 6
        }
        await store.send(.nextTapped) {
            $0.currentPage = 7
        }
        await store.send(.nextTapped)
        await store.receive(.delegate(.onboardingFinished))
    }

    func testCommuteInputsUpdateState() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.originPresetTapped("Дом")) {
            $0.origin = "Дом"
        }
        await store.send(.destinationPresetTapped("Офис")) {
            $0.destination = "Офис"
        }
        await store.send(.morningTimeSelected("08:00")) {
            $0.morningTime = "08:00"
        }
        await store.send(.eveningTimeSelected("19:00")) {
            $0.eveningTime = "19:00"
        }
        await store.send(.dayTapped(.saturday)) {
            $0.selectedDays.insert(.saturday)
        }
        await store.send(.dayTapped(.monday)) {
            $0.selectedDays.remove(.monday)
        }
    }

    func testAddAnotherRouteReturnsToCommuteStart() async {
        var state = OnboardingFeature.State()
        state.currentPage = 7

        let store = TestStore(initialState: state) {
            OnboardingFeature()
        }

        await store.send(.addAnotherRouteTapped) {
            $0.currentPage = 3
        }
    }
}
