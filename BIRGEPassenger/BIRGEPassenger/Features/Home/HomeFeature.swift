import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var activePlan: MockMonthlyCommutePlan?
        var recurringRoutes: [MockRecurringRoute] = []
        var todayPlan: MockTodayCommutePlan?
        var insights: [MockPassengerInsight] = []
        var fallbackTaxi: MockFallbackTaxiOption?
        var isLoadingDashboard = false
        var dashboardError: String?

        var nextPlannedRideSegment: MockPlannedRideSegment? {
            todayPlan?.nextSegment
        }

        var hasNoCommuteToday: Bool {
            todayPlan?.status == .noCommuteToday
        }
    }

    enum Action: ViewAction, Equatable, Sendable {
        case view(View)
        case dashboardLoaded(MockPassengerHomeDashboard)
        case dashboardFailed(String)
        case todayPlanLoaded(MockTodayCommutePlan)
        case delegate(Delegate)

        @CasePathable
        enum View: Equatable, Sendable {
            case onAppear
            case refreshTodayPlan
            case routeTapped(MockRecurringRoute.ID)
            case manageRoutesTapped
            case todayRideTapped
            case fallbackTaxiTapped
            case profileButtonTapped
            case rideHistoryTapped
            case subscriptionTapped
            case aiExplanationTapped
            case projectDemoTapped
        }

        @CasePathable
        enum Delegate: Equatable, Sendable {
            case openRouteManagement(MockRecurringRoute)
            case openRouteList
            case openTodayPlannedRide(MockPlannedRideSegment)
            case openFallbackTaxi
            case openAIExplanation
            case openProjectDemo
            case openProfile
            case openRideHistory
            case openSubscription
        }
    }

    @Dependency(\.passengerRouteClient) var passengerRouteClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.isLoadingDashboard = true
                state.dashboardError = nil
                return .run { send in
                    do {
                        let dashboard = try await passengerRouteClient.homeDashboard()
                        await send(.dashboardLoaded(dashboard))
                    } catch {
                        await send(.dashboardFailed(error.localizedDescription))
                    }
                }

            case .view(.refreshTodayPlan):
                state.isLoadingDashboard = true
                state.dashboardError = nil
                return .run { send in
                    do {
                        let todayPlan = try await passengerRouteClient.todayCommutePlan()
                        await send(.todayPlanLoaded(todayPlan))
                    } catch {
                        await send(.dashboardFailed(error.localizedDescription))
                    }
                }

            case let .view(.routeTapped(id)):
                guard let route = state.recurringRoutes.first(where: { $0.id == id }) else {
                    return .none
                }
                return .send(.delegate(.openRouteManagement(route)))

            case .view(.manageRoutesTapped):
                return .send(.delegate(.openRouteList))

            case .view(.todayRideTapped):
                guard let segment = state.nextPlannedRideSegment else { return .none }
                return .send(.delegate(.openTodayPlannedRide(segment)))

            case .view(.fallbackTaxiTapped):
                guard state.fallbackTaxi != nil else { return .none }
                return .send(.delegate(.openFallbackTaxi))

            case .view(.profileButtonTapped):
                return .send(.delegate(.openProfile))

            case .view(.rideHistoryTapped):
                return .send(.delegate(.openRideHistory))

            case .view(.subscriptionTapped):
                return .send(.delegate(.openSubscription))

            case .view(.aiExplanationTapped):
                return .send(.delegate(.openAIExplanation))

            case .view(.projectDemoTapped):
                return .send(.delegate(.openProjectDemo))

            case let .dashboardLoaded(dashboard):
                state.isLoadingDashboard = false
                state.dashboardError = nil
                state.activePlan = dashboard.activePlan
                state.recurringRoutes = dashboard.recurringRoutes
                state.todayPlan = dashboard.todayPlan
                state.insights = dashboard.insights
                state.fallbackTaxi = dashboard.fallbackTaxi
                return .none

            case let .todayPlanLoaded(todayPlan):
                state.isLoadingDashboard = false
                state.dashboardError = nil
                state.todayPlan = todayPlan
                return .none

            case let .dashboardFailed(message):
                state.isLoadingDashboard = false
                state.dashboardError = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
