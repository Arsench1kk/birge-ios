import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class MyCorridorsFeatureTests: XCTestCase {
    func testRouteListLoadsFromFixtureClient() async {
        let routes = BIRGEProductFixtures.Passenger.recurringRoutes
        let store = TestStore(initialState: MyCorridorsFeature.State()) {
            MyCorridorsFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(routes: routes)
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.routesLoaded(routes)) {
            $0.isLoading = false
            $0.routes = routes
        }
    }

    func testSelectingRouteStoresSelectedDetailState() async {
        let route = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        var state = MyCorridorsFeature.State()
        state.routes = [route]

        let store = TestStore(initialState: state) {
            MyCorridorsFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(detail: route)
        }

        await store.send(.routeTapped(route.id)) {
            $0.isLoading = true
        }
        await store.receive(.routeDetailLoaded(route)) {
            $0.isLoading = false
            $0.selectedRoute = route
            $0.selectedStatusDetail = BIRGEProductFixtures.Passenger.routeStatusDetails[route.status]
            $0.mode = .detail
        }
    }

    func testActiveRouteCanBePaused() async {
        var active = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        active.status = .active
        var paused = active
        paused.status = .paused
        var state = MyCorridorsFeature.State()
        state.routes = [active]
        state.selectedRoute = active
        state.mode = .detail

        let store = TestStore(initialState: state) {
            MyCorridorsFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(pausedRoute: paused)
        }

        await store.send(.pauseRouteTapped) {
            $0.showingPauseConfirmation = true
        }
        await store.send(.pauseConfirmed) {
            $0.showingPauseConfirmation = false
            $0.isUpdatingRoute = true
        }
        await store.receive(.routePaused(paused)) {
            $0.isUpdatingRoute = false
            $0.routes = [paused]
            $0.selectedRoute = paused
            $0.selectedStatusDetail = BIRGEProductFixtures.Passenger.routeStatusDetails[.paused]
        }
    }

    func testPausedRouteCanBeResumed() async {
        var paused = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        paused.status = .paused
        var active = paused
        active.status = .active
        var state = MyCorridorsFeature.State()
        state.routes = [paused]
        state.selectedRoute = paused
        state.mode = .detail

        let store = TestStore(initialState: state) {
            MyCorridorsFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(resumedRoute: active)
        }

        await store.send(.resumeRouteTapped) {
            $0.isUpdatingRoute = true
        }
        await store.receive(.routeResumed(active)) {
            $0.isUpdatingRoute = false
            $0.routes = [active]
            $0.selectedRoute = active
            $0.selectedStatusDetail = BIRGEProductFixtures.Passenger.routeStatusDetails[.active]
        }
    }

    func testLowMatchRouteExposesStatusAction() async {
        var route = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        route.status = .lowDensity
        var state = MyCorridorsFeature.State()
        state.selectedRoute = route
        state.selectedStatusDetail = BIRGEProductFixtures.Passenger.routeStatusDetails[.lowDensity]
        state.mode = .detail

        let store = TestStore(initialState: state) {
            MyCorridorsFeature()
        }

        await store.send(.routeStatusActionTapped) {
            $0.mode = .editSchedule(route)
        }
        await store.receive(.delegate(.editScheduleRequested(route)))
    }

    func testWaitlistRouteExposesStatusAction() async {
        var route = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        route.status = .waitlist
        var state = MyCorridorsFeature.State()
        state.selectedRoute = route
        state.selectedStatusDetail = BIRGEProductFixtures.Passenger.routeStatusDetails[.waitlist]
        state.mode = .detail

        let store = TestStore(initialState: state) {
            MyCorridorsFeature()
        }

        await store.send(.routeStatusActionTapped)
        XCTAssertEqual(store.state.selectedStatusDetail?.waitlistPosition, 3)
    }

    func testAddRouteActionDelegatesAndOpensDraftPlaceholder() async {
        let draft = BIRGEProductFixtures.Passenger.draftRoute
        let store = TestStore(initialState: MyCorridorsFeature.State()) {
            MyCorridorsFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(draft: draft)
        }

        await store.send(.addRouteTapped) {
            $0.mode = .addRouteDraft(nil)
        }
        await store.receive(.addRouteDraftLoaded(draft)) {
            $0.mode = .addRouteDraft(draft)
        }
        await store.receive(.delegate(.addRouteRequested(draft)))
    }

    func testEditRouteActionOpensDraftPlaceholder() async {
        let route = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        var state = MyCorridorsFeature.State()
        state.selectedRoute = route

        let store = TestStore(initialState: state) {
            MyCorridorsFeature()
        }

        await store.send(.editRouteTapped) {
            $0.mode = .editRouteDraft(route)
        }
        await store.receive(.delegate(.editRouteRequested(route)))
    }

    func testEditPickupDropoffScheduleActionsAreExplicit() async {
        let route = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        var state = MyCorridorsFeature.State()
        state.selectedRoute = route

        let store = TestStore(initialState: state) {
            MyCorridorsFeature()
        }

        await store.send(.editPickupTapped) {
            $0.mode = .editPickup(route)
        }
        await store.receive(.delegate(.editPickupRequested(route)))
        await store.send(.editDropoffTapped) {
            $0.mode = .editDropoff(route)
        }
        await store.receive(.delegate(.editDropoffRequested(route)))
        await store.send(.editScheduleTapped) {
            $0.mode = .editSchedule(route)
        }
        await store.receive(.delegate(.editScheduleRequested(route)))
    }

    func testLoadFailureStoresErrorState() async {
        let store = TestStore(initialState: MyCorridorsFeature.State()) {
            MyCorridorsFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(
                routeList: { throw MockFrontendError("Routes unavailable.") }
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.routesFailed("Routes unavailable.")) {
            $0.isLoading = false
            $0.errorMessage = "Routes unavailable."
        }
    }

    private static func routeClient(
        routes: [MockRecurringRoute] = BIRGEProductFixtures.Passenger.recurringRoutes,
        detail: MockRecurringRoute = BIRGEProductFixtures.Passenger.recurringRoutes[0],
        draft: MockRouteDraft = BIRGEProductFixtures.Passenger.draftRoute,
        pausedRoute: MockRecurringRoute? = nil,
        resumedRoute: MockRecurringRoute? = nil,
        routeList: @escaping @Sendable () async throws -> [MockRecurringRoute] = {
            BIRGEProductFixtures.Passenger.recurringRoutes
        }
    ) -> PassengerRouteClient {
        PassengerRouteClient(
            draftRoute: { draft },
            searchAddresses: { _ in BIRGEProductFixtures.Passenger.addressSearchResults },
            suggestedPickupNodes: { _ in BIRGEProductFixtures.Passenger.pickupNodes },
            suggestedDropoffNodes: { _ in BIRGEProductFixtures.Passenger.dropoffNodes },
            saveRouteDraft: { $0 },
            homeDashboard: { BIRGEProductFixtures.Passenger.homeDashboard },
            todayCommutePlan: { BIRGEProductFixtures.Passenger.todayCommutePlan },
            recurringRoutes: routeList,
            routeDetail: { _ in detail },
            pauseRoute: { _ in pausedRoute ?? detail },
            resumeRoute: { _ in resumedRoute ?? detail },
            plannedRide: { _ in BIRGEProductFixtures.Passenger.plannedCommuteRide },
            todayPlannedRide: { BIRGEProductFixtures.Passenger.plannedCommuteRide },
            advancePlannedRideStatus: { _, status in
                var ride = BIRGEProductFixtures.Passenger.plannedCommuteRide
                ride.status = status
                return ride
            },
            rideDayTimelines: { BIRGEProductFixtures.Passenger.rideDayTimelines }
        )
    }
}
