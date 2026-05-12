import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class HomeFeatureTests: XCTestCase {
    func testDashboardLoadSuccessPopulatesActivePlanRoutesAndTodayPlan() async {
        let dashboard = BIRGEProductFixtures.Passenger.homeDashboard
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(dashboard: dashboard)
        }

        await store.send(.view(.onAppear)) {
            $0.isLoadingDashboard = true
            $0.dashboardError = nil
        }
        await store.receive(.dashboardLoaded(dashboard)) {
            $0.isLoadingDashboard = false
            $0.activePlan = dashboard.activePlan
            $0.recurringRoutes = dashboard.recurringRoutes
            $0.todayPlan = dashboard.todayPlan
            $0.insights = dashboard.insights
            $0.fallbackTaxi = dashboard.fallbackTaxi
        }
    }

    func testDashboardLoadFailureStoresErrorState() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(
                dashboardResult: { throw MockFrontendError("Dashboard unavailable.") }
            )
        }

        await store.send(.view(.onAppear)) {
            $0.isLoadingDashboard = true
            $0.dashboardError = nil
        }
        await store.receive(.dashboardFailed("Dashboard unavailable.")) {
            $0.isLoadingDashboard = false
            $0.dashboardError = "Dashboard unavailable."
        }
    }

    func testActiveRouteSelectionDelegatesToRouteManagement() async {
        let route = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        var state = HomeFeature.State()
        state.recurringRoutes = [route]

        let store = TestStore(initialState: state) {
            HomeFeature()
        }

        await store.send(.view(.routeTapped(route.id)))
        await store.receive(\.delegate.openRouteManagement, route)
    }

    func testNoCommuteTodayStateIsRepresented() async {
        let dashboard = MockPassengerHomeDashboard(
            activePlan: BIRGEProductFixtures.Passenger.activeCommutePlan,
            recurringRoutes: BIRGEProductFixtures.Passenger.recurringRoutes,
            todayPlan: BIRGEProductFixtures.Passenger.noCommuteTodayPlan,
            insights: [],
            fallbackTaxi: BIRGEProductFixtures.Passenger.fallbackTaxi
        )
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(dashboard: dashboard)
        }

        await store.send(.view(.onAppear)) {
            $0.isLoadingDashboard = true
        }
        await store.receive(.dashboardLoaded(dashboard)) {
            $0.isLoadingDashboard = false
            $0.activePlan = dashboard.activePlan
            $0.recurringRoutes = dashboard.recurringRoutes
            $0.todayPlan = dashboard.todayPlan
            $0.insights = []
            $0.fallbackTaxi = dashboard.fallbackTaxi
        }

        XCTAssertTrue(store.state.hasNoCommuteToday)
    }

    func testPausedLowMatchAndWaitlistRouteStatusVariantsAreRepresented() async {
        var paused = BIRGEProductFixtures.Passenger.recurringRoutes[0]
        paused.status = .paused
        let lowMatch = MockRecurringRoute(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000020")!,
            name: paused.name,
            originName: paused.originName,
            destinationName: paused.destinationName,
            pickupNode: paused.pickupNode,
            dropoffNode: paused.dropoffNode,
            schedule: paused.schedule,
            status: .lowDensity,
            reliabilityPercent: paused.reliabilityPercent
        )
        let waitlist = MockRecurringRoute(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000021")!,
            name: paused.name,
            originName: paused.originName,
            destinationName: paused.destinationName,
            pickupNode: paused.pickupNode,
            dropoffNode: paused.dropoffNode,
            schedule: paused.schedule,
            status: .waitlist,
            reliabilityPercent: paused.reliabilityPercent
        )

        let dashboard = MockPassengerHomeDashboard(
            activePlan: BIRGEProductFixtures.Passenger.activeCommutePlan,
            recurringRoutes: [paused, lowMatch, waitlist],
            todayPlan: MockTodayCommutePlan(
                id: UUID(uuidString: "82000000-0000-0000-0000-000000000020")!,
                status: .lowMatch,
                dateLabel: "Today",
                nextSegment: nil
            ),
            insights: [],
            fallbackTaxi: nil
        )
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(dashboard: dashboard)
        }

        await store.send(.view(.onAppear)) {
            $0.isLoadingDashboard = true
        }
        await store.receive(.dashboardLoaded(dashboard)) {
            $0.isLoadingDashboard = false
            $0.activePlan = dashboard.activePlan
            $0.recurringRoutes = [paused, lowMatch, waitlist]
            $0.todayPlan = dashboard.todayPlan
            $0.insights = []
            $0.fallbackTaxi = nil
        }

        XCTAssertEqual(Set(store.state.recurringRoutes.map(\.status)), [.paused, .lowDensity, .waitlist])
        XCTAssertEqual(store.state.todayPlan?.status, .lowMatch)
    }

    func testFallbackTaxiActionDelegatesSeparatelyFromPrimaryCommuteActions() async {
        var state = HomeFeature.State()
        state.fallbackTaxi = BIRGEProductFixtures.Passenger.fallbackTaxi

        let store = TestStore(initialState: state) {
            HomeFeature()
        }

        await store.send(.view(.fallbackTaxiTapped))
        await store.receive(\.delegate.openFallbackTaxi)
    }

    func testTodayRideActionDelegatesPlannedRideSegment() async {
        var state = HomeFeature.State()
        state.todayPlan = BIRGEProductFixtures.Passenger.todayCommutePlan

        let store = TestStore(initialState: state) {
            HomeFeature()
        }

        await store.send(.view(.todayRideTapped))
        await store.receive(
            \.delegate.openTodayPlannedRide,
            BIRGEProductFixtures.Passenger.plannedRideSegment
        )
    }

    func testRefreshTodayPlanLoadsOnlyTodayPlan() async {
        let todayPlan = BIRGEProductFixtures.Passenger.noCommuteTodayPlan
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(todayPlan: todayPlan)
        }

        await store.send(.view(.refreshTodayPlan)) {
            $0.isLoadingDashboard = true
            $0.dashboardError = nil
        }
        await store.receive(.todayPlanLoaded(todayPlan)) {
            $0.isLoadingDashboard = false
            $0.todayPlan = todayPlan
        }
    }

    private static func routeClient(
        dashboard: MockPassengerHomeDashboard = BIRGEProductFixtures.Passenger.homeDashboard,
        todayPlan: MockTodayCommutePlan = BIRGEProductFixtures.Passenger.todayCommutePlan,
        dashboardResult: @escaping @Sendable () async throws -> MockPassengerHomeDashboard = {
            BIRGEProductFixtures.Passenger.homeDashboard
        }
    ) -> PassengerRouteClient {
        PassengerRouteClient(
            draftRoute: { BIRGEProductFixtures.Passenger.draftRoute },
            searchAddresses: { _ in BIRGEProductFixtures.Passenger.addressSearchResults },
            suggestedPickupNodes: { _ in BIRGEProductFixtures.Passenger.pickupNodes },
            suggestedDropoffNodes: { _ in BIRGEProductFixtures.Passenger.dropoffNodes },
            saveRouteDraft: { $0 },
            homeDashboard: {
                if dashboard == BIRGEProductFixtures.Passenger.homeDashboard {
                    return try await dashboardResult()
                }
                return dashboard
            },
            todayCommutePlan: { todayPlan },
            recurringRoutes: { BIRGEProductFixtures.Passenger.recurringRoutes },
            routeDetail: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
            pauseRoute: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
            resumeRoute: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
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
