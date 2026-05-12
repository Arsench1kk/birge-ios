import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class PassengerPlannedRideFeatureTests: XCTestCase {
    func testPlannedRideLoadsFromFixtureClient() async {
        let ride = BIRGEProductFixtures.Passenger.plannedCommuteRide
        let store = TestStore(initialState: PassengerPlannedRideFeature.State(rideID: ride.id)) {
            PassengerPlannedRideFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(ride: ride)
        }

        await store.send(.view(.onAppear)) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.plannedRideLoaded(ride)) {
            $0.isLoading = false
            $0.rideID = ride.id
            $0.plannedRide = ride
        }
    }

    func testLifecycleStartsFromDriverEnRouteFixture() {
        let ride = BIRGEProductFixtures.Passenger.plannedCommuteRide
        let state = PassengerPlannedRideFeature.State(plannedRide: ride)

        XCTAssertEqual(state.currentStatus, .driverEnRoute)
        XCTAssertEqual(state.boardingCode, BIRGEProductFixtures.Passenger.boardingCode)
    }

    func testAdvanceToDriverArrived() async {
        let initialRide = BIRGEProductFixtures.Passenger.plannedCommuteRide
        let arrivedRide = Self.ride(status: .driverArrived)
        let store = TestStore(initialState: PassengerPlannedRideFeature.State(plannedRide: initialRide)) {
            PassengerPlannedRideFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(advancedRide: arrivedRide)
        }

        await store.send(.view(.driverArrivedTapped)) {
            $0.isAdvancing = true
            $0.errorMessage = nil
        }
        await store.receive(.lifecycleAdvanced(arrivedRide)) {
            $0.isAdvancing = false
            $0.rideID = arrivedRide.id
            $0.plannedRide = arrivedRide
        }
    }

    func testShowBoardingCodeMovesToBoarding() async {
        let boardingRide = Self.ride(status: .boarding)
        let store = TestStore(initialState: PassengerPlannedRideFeature.State(plannedRide: BIRGEProductFixtures.Passenger.plannedCommuteRide)) {
            PassengerPlannedRideFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(advancedRide: boardingRide)
        }

        await store.send(.view(.showBoardingCodeTapped)) {
            $0.isAdvancing = true
        }
        await store.receive(.lifecycleAdvanced(boardingRide)) {
            $0.isAdvancing = false
            $0.plannedRide = boardingRide
        }
        XCTAssertEqual(store.state.boardingCode?.value, "4821")
    }

    func testConfirmBoardingStartsInProgressState() async {
        let inProgressRide = Self.ride(status: .inProgress)
        let store = TestStore(initialState: PassengerPlannedRideFeature.State(plannedRide: Self.ride(status: .boarding))) {
            PassengerPlannedRideFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(advancedRide: inProgressRide)
        }

        await store.send(.view(.boardingConfirmedTapped)) {
            $0.isAdvancing = true
        }
        await store.receive(.lifecycleAdvanced(inProgressRide)) {
            $0.isAdvancing = false
            $0.plannedRide = inProgressRide
        }
    }

    func testCompleteRideCreatesCompletedSummary() async {
        let completedRide = Self.ride(status: .completed)
        let store = TestStore(initialState: PassengerPlannedRideFeature.State(plannedRide: Self.ride(status: .inProgress))) {
            PassengerPlannedRideFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(advancedRide: completedRide)
        }

        await store.send(.view(.rideCompletedTapped)) {
            $0.isAdvancing = true
        }
        await store.receive(.lifecycleAdvanced(completedRide)) {
            $0.isAdvancing = false
            $0.plannedRide = completedRide
        }
        XCTAssertEqual(store.state.completedSummary, BIRGEProductFixtures.Passenger.completedCommuteSummary)
    }

    func testDelayedReplacementPickupChangedMissedPickupAndCancelledStatesAreRepresented() async {
        for status in [PlannedRideStatus.delayed, .replacementAssigned, .pickupChanged, .passengerMissedPickup, .cancelled] {
            let edgeRide = Self.ride(status: status)
            let store = TestStore(initialState: PassengerPlannedRideFeature.State(plannedRide: BIRGEProductFixtures.Passenger.plannedCommuteRide)) {
                PassengerPlannedRideFeature()
            }

            await store.send(.lifecycleAdvanced(edgeRide)) {
                $0.isAdvancing = false
                $0.plannedRide = edgeRide
            }
            XCTAssertEqual(store.state.currentStatus, status)
            XCTAssertEqual(store.state.plannedRide?.edgeCase?.status, status)
        }
    }

    func testSupportSafetyShareAndReportIssueActionsDelegate() async {
        let ride = BIRGEProductFixtures.Passenger.plannedCommuteRide
        let store = TestStore(initialState: PassengerPlannedRideFeature.State(plannedRide: ride)) {
            PassengerPlannedRideFeature()
        }

        await store.send(.view(.reportIssueTapped))
        await store.receive(\.delegate.reportIssue, ride.id)

        await store.send(.view(.supportTapped))
        await store.receive(\.delegate.support, ride.id)

        await store.send(.view(.safetyTapped))
        await store.receive(\.delegate.safety, ride.id)

        await store.send(.view(.shareStatusTapped))
        await store.receive(\.delegate.shareStatus, ride.id)
    }

    nonisolated private static func ride(status: PlannedRideStatus) -> MockPlannedCommuteRide {
        var ride = BIRGEProductFixtures.Passenger.plannedCommuteRide
        ride.status = status
        ride.completedSummary = status == .completed ? BIRGEProductFixtures.Passenger.completedCommuteSummary : nil
        ride.edgeCase = BIRGEProductFixtures.Passenger.rideDayEdgeCases[status]
        return ride
    }

    private static func routeClient(
        ride: MockPlannedCommuteRide = BIRGEProductFixtures.Passenger.plannedCommuteRide,
        advancedRide: MockPlannedCommuteRide? = nil
    ) -> PassengerRouteClient {
        PassengerRouteClient(
            draftRoute: { BIRGEProductFixtures.Passenger.draftRoute },
            searchAddresses: { _ in BIRGEProductFixtures.Passenger.addressSearchResults },
            suggestedPickupNodes: { _ in BIRGEProductFixtures.Passenger.pickupNodes },
            suggestedDropoffNodes: { _ in BIRGEProductFixtures.Passenger.dropoffNodes },
            saveRouteDraft: { $0 },
            homeDashboard: { BIRGEProductFixtures.Passenger.homeDashboard },
            todayCommutePlan: { BIRGEProductFixtures.Passenger.todayCommutePlan },
            recurringRoutes: { BIRGEProductFixtures.Passenger.recurringRoutes },
            routeDetail: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
            pauseRoute: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
            resumeRoute: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
            plannedRide: { _ in ride },
            todayPlannedRide: { ride },
            advancePlannedRideStatus: { _, status in advancedRide ?? Self.ride(status: status) },
            rideDayTimelines: { BIRGEProductFixtures.Passenger.rideDayTimelines }
        )
    }
}
