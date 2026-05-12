import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class PassengerAppFeatureTests: XCTestCase {
    func testHomeAIExplanationOpensExplanationScreen() async {
        let store = TestStore(initialState: PassengerAppFeature.State()) {
            PassengerAppFeature()
        }

        await store.send(.home(.delegate(.openAIExplanation)))

        let path = Array(store.state.path)
        XCTAssertEqual(path.count, 1)
        guard case .aiExplanation = path.last else {
            XCTFail("Expected AIExplanationFeature at the top of the stack")
            return
        }
    }

    func testHomeProjectDemoOpensDemoScreen() async {
        let store = TestStore(initialState: PassengerAppFeature.State()) {
            PassengerAppFeature()
        }

        await store.send(.home(.delegate(.openProjectDemo)))

        let path = Array(store.state.path)
        XCTAssertEqual(path.count, 1)
        guard case .projectDemo = path.last else {
            XCTFail("Expected ProjectDemoFeature at the top of the stack")
            return
        }
    }

    func testAIExplanationTryCorridorsOpensCorridorList() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.aiExplanation(AIExplanationFeature.State()))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .aiExplanation(.delegate(.openCorridorList))
                )
            )
        )

        let path = Array(store.state.path)
        XCTAssertEqual(path.count, 2)
        guard case .corridorList = path.last else {
            XCTFail("Expected CorridorListFeature at the top of the stack")
            return
        }
    }

    func testHomeSubscriptionOpensSubscriptionsScreen() async {
        let store = TestStore(initialState: PassengerAppFeature.State()) {
            PassengerAppFeature()
        }

        await store.send(.home(.delegate(.openSubscription)))

        let path = Array(store.state.path)
        XCTAssertEqual(path.count, 1)
        guard case .subscriptions = path.last else {
            XCTFail("Expected SubscriptionsFeature at the top of the stack")
            return
        }
    }

    func testHomeFallbackTaxiOpensRideRequestAsSecondaryFlow() async {
        let store = TestStore(initialState: PassengerAppFeature.State()) {
            PassengerAppFeature()
        }

        await store.send(.home(.delegate(.openFallbackTaxi)))

        guard case .rideRequest = Array(store.state.path).last else {
            XCTFail("Expected RideRequestFeature at the top of the stack")
            return
        }
    }

    func testHomeRouteManagementDelegatesOpenMyCorridorsPlaceholder() async {
        let store = TestStore(initialState: PassengerAppFeature.State()) {
            PassengerAppFeature()
        }

        await store.send(.home(.delegate(.openRouteManagement(BIRGEProductFixtures.Passenger.recurringRoutes[0]))))

        guard case .myCorridors = Array(store.state.path).last else {
            XCTFail("Expected MyCorridorsFeature at the top of the stack")
            return
        }
    }

    func testHomeTodayRideDelegatesOpenPlannedRideFeature() async {
        let store = TestStore(initialState: PassengerAppFeature.State()) {
            PassengerAppFeature()
        }

        await store.send(.home(.delegate(.openTodayPlannedRide(BIRGEProductFixtures.Passenger.plannedRideSegment))))

        guard case let .plannedRide(plannedRideState) = Array(store.state.path).last else {
            XCTFail("Expected PassengerPlannedRideFeature at the top of the stack")
            return
        }
        XCTAssertEqual(plannedRideState.rideID, BIRGEProductFixtures.Passenger.plannedRideSegment.id)
    }

    func testPlannedRideDoneReturnsHome() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.plannedRide(PassengerPlannedRideFeature.State(
            plannedRide: BIRGEProductFixtures.Passenger.plannedCommuteRide
        )))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .plannedRide(.delegate(.done))
                )
            )
        )

        XCTAssertTrue(store.state.path.isEmpty)
    }

    func testPlannedRideReportSupportSafetyAndShareDelegatesRouteToSupportFeature() async {
        let rideID = BIRGEProductFixtures.Passenger.plannedCommuteRide.id
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.plannedRide(PassengerPlannedRideFeature.State(
            plannedRide: BIRGEProductFixtures.Passenger.plannedCommuteRide
        )))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(.element(id: 0, action: .plannedRide(.delegate(.reportIssue(rideID)))))
        )
        guard case let .support(reportState) = Array(store.state.path).last else {
            XCTFail("Expected support feature for report issue")
            return
        }
        XCTAssertEqual(reportState.mode, .issueReport)
        XCTAssertEqual(reportState.context?.plannedRideID, rideID)

        await store.send(
            .path(.element(id: 0, action: .plannedRide(.delegate(.support(rideID)))))
        )
        guard case let .support(supportState) = Array(store.state.path).last else {
            XCTFail("Expected support feature for inbox")
            return
        }
        XCTAssertEqual(supportState.mode, .inbox)

        await store.send(
            .path(.element(id: 0, action: .plannedRide(.delegate(.safety(rideID)))))
        )
        guard case let .support(safetyState) = Array(store.state.path).last else {
            XCTFail("Expected support feature for safety")
            return
        }
        XCTAssertEqual(safetyState.mode, .safetyCenter)

        await store.send(
            .path(.element(id: 0, action: .plannedRide(.delegate(.shareStatus(rideID)))))
        )
        guard case let .support(shareState) = Array(store.state.path).last else {
            XCTFail("Expected support feature for share status")
            return
        }
        XCTAssertEqual(shareState.mode, .shareStatus)
    }

    func testSubscriptionActivationFinishedReturnsHome() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.subscriptions(SubscriptionsFeature.State()))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .subscriptions(.delegate(.activationFinished))
                )
            )
        )

        XCTAssertTrue(store.state.path.isEmpty)
    }

    func testHomeRideHistoryOpensMyCorridorsScreen() async {
        let store = TestStore(initialState: PassengerAppFeature.State()) {
            PassengerAppFeature()
        }

        await store.send(.home(.delegate(.openRideHistory)))

        let path = Array(store.state.path)
        XCTAssertEqual(path.count, 1)
        guard case .myCorridors = path.last else {
            XCTFail("Expected MyCorridorsFeature at the top of the stack")
            return
        }
    }

    func testRideRequestBackReturnsToHome() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.rideRequest(RideRequestFeature.State()))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .rideRequest(.delegate(.back))
                )
            )
        )

        XCTAssertTrue(store.state.path.isEmpty)
    }

    func testRideMatchedNavigatesToOfferFoundWithDriverInfo() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.searching(SearchingFeature.State(rideId: "ride-123")))

        let driverInfo = SearchingFeature.DriverInfo(
            driverId: "driver-123",
            driverName: "Асан Бекович",
            driverRating: 4.9,
            driverVehicle: "Chevrolet Nexia",
            driverPlate: "777 ABA 02",
            etaSeconds: 240
        )

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .searching(
                        .delegate(
                            .rideMatched(rideID: "ride-123", driverInfo)
                        )
                    )
                )
            )
        )

        let path = Array(store.state.path)
        XCTAssertEqual(path.count, 2)
        guard case let .offerFound(offerState) = path.last else {
            XCTFail("Expected OfferFoundFeature at the top of the stack")
            return
        }
        XCTAssertEqual(offerState.rideId, "ride-123")
        XCTAssertEqual(offerState.driverInfo, driverInfo)
    }

    func testOfferConfirmedNavigatesToRideFeatureWithDriverInfo() async {
        let driverInfo = SearchingFeature.DriverInfo(
            driverId: "driver-123",
            driverName: "Асан Бекович",
            driverRating: 4.9,
            driverVehicle: "Chevrolet Nexia",
            driverPlate: "777 ABA 02",
            etaSeconds: 240
        )

        var initialState = PassengerAppFeature.State()
        initialState.path.append(.searching(SearchingFeature.State(rideId: "ride-123")))
        initialState.path.append(.offerFound(OfferFoundFeature.State(
            rideId: "ride-123",
            driverInfo: driverInfo
        )))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 1,
                    action: .offerFound(
                        .delegate(
                            .confirmed(rideID: "ride-123", driverInfo)
                        )
                    )
                )
            )
        )

        let path = Array(store.state.path)
        XCTAssertEqual(path.count, 2)
        guard case let .ride(rideState) = path.last else {
            XCTFail("Expected RideFeature at the top of the stack")
            return
        }
        XCTAssertEqual(rideState.rideId, "ride-123")
        XCTAssertEqual(rideState.status, .matched)
        XCTAssertEqual(rideState.etaSeconds, 240)
        XCTAssertEqual(rideState.driverName, "Асан Бекович")
        XCTAssertEqual(rideState.driverRating, 4.9)
        XCTAssertEqual(rideState.driverVehicle, "Chevrolet Nexia")
        XCTAssertEqual(rideState.driverPlate, "777 ABA 02")
    }

    func testOfferDeclinedClearsRideFlow() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.searching(SearchingFeature.State(rideId: "ride-123")))
        initialState.path.append(.offerFound(OfferFoundFeature.State(
            rideId: "ride-123",
            driverInfo: SearchingFeature.DriverInfo(
                driverId: "driver-123",
                driverName: "Асан",
                driverRating: 4.9,
                driverVehicle: "Toyota Camry",
                driverPlate: "777 ABA 02",
                etaSeconds: 240
            )
        )))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 1,
                    action: .offerFound(.delegate(.declined))
                )
            )
        )

        XCTAssertTrue(store.state.path.isEmpty)
    }

    func testSearchingCancelledClearsRideFlow() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.rideRequest(RideRequestFeature.State()))
        initialState.path.append(.searching(SearchingFeature.State(rideId: "ride-123")))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 1,
                    action: .searching(.delegate(.cancelled))
                )
            )
        )

        XCTAssertTrue(store.state.path.isEmpty)
    }

    func testRideCompleteDoneClearsRideFlow() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.ride(PassengerAppFeature.State.testRideState()))
        initialState.path.append(.rideComplete(RideCompleteFeature.State()))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 1,
                    action: .rideComplete(.delegate(.done))
                )
            )
        )

        XCTAssertTrue(store.state.path.isEmpty)
    }

    func testProfileLogoutDelegatesToRoot() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.profile(ProfileFeature.State()))

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .profile(.delegate(.loggedOut))
                )
            )
        )

        await store.receive(\.delegate.loggedOut)
    }
}

private extension PassengerAppFeature.State {
    static func testRideState() -> RideFeature.State {
        RideFeature.State(
            rideId: "ride-123",
            status: .matched,
            etaSeconds: 240,
            driverName: "Асан",
            driverRating: 4.9,
            driverVehicle: "Toyota Camry",
            driverPlate: "777 ABA 02"
        )
    }
}
