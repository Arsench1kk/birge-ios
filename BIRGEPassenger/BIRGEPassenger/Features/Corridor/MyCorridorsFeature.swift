import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct MyCorridorsFeature {
    @ObservableState
    struct State: Equatable {
        enum Mode: Equatable, Sendable {
            case list
            case detail
            case addRouteDraft(MockRouteDraft?)
            case editRouteDraft(MockRecurringRoute)
            case editPickup(MockRecurringRoute)
            case editDropoff(MockRecurringRoute)
            case editSchedule(MockRecurringRoute)
        }

        var routes: [MockRecurringRoute] = []
        var selectedRoute: MockRecurringRoute?
        var selectedStatusDetail: MockRouteStatusDetail?
        var mode: Mode = .list
        var isLoading = false
        var isUpdatingRoute = false
        var showingPauseConfirmation = false
        var errorMessage: String?

        var isEmpty: Bool {
            !isLoading && routes.isEmpty
        }
    }

    enum Action: Equatable, Sendable {
        case onAppear
        case routesLoaded([MockRecurringRoute])
        case routesFailed(String)
        case routeTapped(MockRecurringRoute.ID)
        case routeDetailLoaded(MockRecurringRoute)
        case addRouteTapped
        case addRouteDraftLoaded(MockRouteDraft)
        case editRouteTapped
        case editPickupTapped
        case editDropoffTapped
        case editScheduleTapped
        case pauseRouteTapped
        case pauseConfirmed
        case routePaused(MockRecurringRoute)
        case resumeRouteTapped
        case routeResumed(MockRecurringRoute)
        case routeStatusActionTapped
        case saveEditedRoutePlaceholderTapped
        case closeDetailTapped
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            case addRouteRequested(MockRouteDraft?)
            case editRouteRequested(MockRecurringRoute)
            case editPickupRequested(MockRecurringRoute)
            case editDropoffRequested(MockRecurringRoute)
            case editScheduleRequested(MockRecurringRoute)
        }
    }

    @Dependency(\.passengerRouteClient) var passengerRouteClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let routes = try await passengerRouteClient.recurringRoutes()
                        await send(.routesLoaded(routes))
                    } catch {
                        await send(.routesFailed(error.localizedDescription))
                    }
                }

            case let .routesLoaded(routes):
                state.isLoading = false
                state.routes = routes
                return .none

            case let .routesFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let .routeTapped(id):
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let route = try await passengerRouteClient.routeDetail(id)
                        await send(.routeDetailLoaded(route))
                    } catch {
                        await send(.routesFailed(error.localizedDescription))
                    }
                }

            case let .routeDetailLoaded(route):
                state.isLoading = false
                state.selectedRoute = route
                state.selectedStatusDetail = BIRGEProductFixtures.Passenger.routeStatusDetails[route.status]
                state.mode = .detail
                return .none

            case .addRouteTapped:
                state.mode = .addRouteDraft(nil)
                return .run { send in
                    let draft = await passengerRouteClient.draftRoute()
                    await send(.addRouteDraftLoaded(draft))
                }

            case let .addRouteDraftLoaded(draft):
                state.mode = .addRouteDraft(draft)
                return .send(.delegate(.addRouteRequested(draft)))

            case .editRouteTapped:
                guard let route = state.selectedRoute else { return .none }
                state.mode = .editRouteDraft(route)
                return .send(.delegate(.editRouteRequested(route)))

            case .editPickupTapped:
                guard let route = state.selectedRoute else { return .none }
                state.mode = .editPickup(route)
                return .send(.delegate(.editPickupRequested(route)))

            case .editDropoffTapped:
                guard let route = state.selectedRoute else { return .none }
                state.mode = .editDropoff(route)
                return .send(.delegate(.editDropoffRequested(route)))

            case .editScheduleTapped:
                guard let route = state.selectedRoute else { return .none }
                state.mode = .editSchedule(route)
                return .send(.delegate(.editScheduleRequested(route)))

            case .pauseRouteTapped:
                state.showingPauseConfirmation = state.selectedRoute != nil
                return .none

            case .pauseConfirmed:
                guard let route = state.selectedRoute else { return .none }
                state.showingPauseConfirmation = false
                state.isUpdatingRoute = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let route = try await passengerRouteClient.pauseRoute(route.id)
                        await send(.routePaused(route))
                    } catch {
                        await send(.routesFailed(error.localizedDescription))
                    }
                }

            case let .routePaused(route):
                state.isUpdatingRoute = false
                state.upsertRoute(route)
                state.selectedRoute = route
                state.selectedStatusDetail = BIRGEProductFixtures.Passenger.routeStatusDetails[route.status]
                return .none

            case .resumeRouteTapped:
                guard let route = state.selectedRoute else { return .none }
                state.isUpdatingRoute = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let route = try await passengerRouteClient.resumeRoute(route.id)
                        await send(.routeResumed(route))
                    } catch {
                        await send(.routesFailed(error.localizedDescription))
                    }
                }

            case let .routeResumed(route):
                state.isUpdatingRoute = false
                state.upsertRoute(route)
                state.selectedRoute = route
                state.selectedStatusDetail = BIRGEProductFixtures.Passenger.routeStatusDetails[route.status]
                return .none

            case .routeStatusActionTapped:
                guard let route = state.selectedRoute else { return .none }
                switch route.status {
                case .lowDensity:
                    state.mode = .editSchedule(route)
                    return .send(.delegate(.editScheduleRequested(route)))
                case .waitlist:
                    state.mode = .detail
                    return .none
                case .paused:
                    return .send(.resumeRouteTapped)
                default:
                    state.mode = .editRouteDraft(route)
                    return .send(.delegate(.editRouteRequested(route)))
                }

            case .saveEditedRoutePlaceholderTapped:
                state.mode = .detail
                return .none

            case .closeDetailTapped:
                state.selectedRoute = nil
                state.selectedStatusDetail = nil
                state.mode = .list
                state.showingPauseConfirmation = false
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension MyCorridorsFeature.State {
    mutating func upsertRoute(_ route: MockRecurringRoute) {
        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index] = route
        } else {
            routes.append(route)
        }
    }
}
