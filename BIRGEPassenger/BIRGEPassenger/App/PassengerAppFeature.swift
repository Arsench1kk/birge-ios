import ComposableArchitecture

@Reducer struct PassengerAppFeature {
    @ObservableState
    struct State: Equatable {
        var home = HomeFeature.State()
        var path = StackState<Path.State>()

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.home == rhs.home
        }
    }

    @Reducer
    @CasePathable
    enum Path {
        case rideRequest(RideRequestFeature)
        case searching(SearchingFeature)
        case activeRide(ActiveRideFeature)
        case ride(RideFeature)
        case rideComplete(RideCompleteFeature)
        case profile(ProfileFeature)
    }

    enum Action: Sendable {
        case home(HomeFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        enum Delegate: Sendable {
            case loggedOut
        }
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Reduce { state, action in
            switch action {

            // Home → RideRequest
            case .home(.delegate(.openRideRequest)):
                state.path.append(.rideRequest(RideRequestFeature.State()))
                return .none
            
            // Home → Profile
            case .home(.delegate(.openProfile)):
                state.path.append(.profile(ProfileFeature.State()))
                return .none

            // RideRequest → Searching
            case .path(.element(_, action: .rideRequest(.delegate(.rideRequested)))):
                state.path.append(.searching(SearchingFeature.State()))
                return .none

            // Searching → Ride (production flow)
            case .path(.element(_, action: .searching(.delegate(.driverFound)))):
                // In production, the searching phase returns a ride ID from the backend
                // For now, use a placeholder ID — real integration in IOS-017
                state.path.append(.ride(RideFeature.State(rideId: "ride-\(UUID().uuidString.prefix(8))")))
                return .none

            // Searching → Home (cancelled)
            case .path(.element(_, action: .searching(.delegate(.cancelled)))):
                state.path.removeAll()
                return .none

            // ActiveRide → RideComplete (legacy simulation flow)
            case .path(.element(_, action: .activeRide(.delegate(.rideCompleted)))):
                state.path.append(.rideComplete(RideCompleteFeature.State()))
                return .none

            // ActiveRide → Home (cancelled, legacy)
            case .path(.element(_, action: .activeRide(.delegate(.cancelled)))):
                state.path.removeAll()
                return .none

            // Ride → RideComplete (production flow)
            case .path(.element(_, action: .ride(.delegate(.completed)))):
                state.path.append(.rideComplete(RideCompleteFeature.State()))
                return .none

            // Ride → Home (cancelled, production flow)
            case .path(.element(_, action: .ride(.delegate(.cancelled)))):
                state.path.removeAll()
                return .none

            // RideComplete → Home
            case .path(.element(_, action: .rideComplete(.delegate(.done)))):
                state.path.removeAll()
                return .none

            // Profile → Logout
            case .path(.element(_, action: .profile(.delegate(.loggedOut)))):
                return .send(.delegate(.loggedOut))

            default:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
