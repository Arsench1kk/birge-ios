import ComposableArchitecture
import Foundation

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
        case corridorList(CorridorListFeature)
        case corridorDetail(CorridorDetailFeature)
        #if DEBUG
        case activeRide(ActiveRideFeature)
        #endif
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

            // Home → Corridor detail
            case .home(.delegate(.openCorridor(let corridor))):
                state.path.append(.corridorDetail(CorridorDetailFeature.State(corridor: corridor)))
                return .none
            
            // Home → Profile
            case .home(.delegate(.openProfile)):
                state.path.append(.profile(ProfileFeature.State()))
                return .none

            // Home → Corridor List
            case .home(.delegate(.openCorridorList)):
                state.path.append(.corridorList(CorridorListFeature.State()))
                return .none

            // Corridor List → Corridor Detail
            case .path(.element(_, action: .corridorList(.delegate(.corridorSelected(let corridor))))):
                state.path.append(.corridorDetail(CorridorDetailFeature.State(corridor: corridor)))
                return .none

            // Home → Ride History (stub — profile for now)
            case .home(.delegate(.openRideHistory)):
                return .none

            // Home → Subscription (stub)
            case .home(.delegate(.openSubscription)):
                return .none

            // RideRequest → Searching
            case .path(.element(_, action: .rideRequest(.delegate(.rideCreated(let rideId))))):
                state.path.append(.searching(SearchingFeature.State(rideId: rideId)))
                return .none

            // RideRequest → Home
            case .path(.element(_, action: .rideRequest(.delegate(.back)))):
                state.path.removeLast()
                return .none

            // Searching → Ride (production flow)
            case .path(.element(_, action: .searching(.delegate(.rideMatched(let rideID, let driverInfo))))):
                state.path.append(.ride(RideFeature.State(
                    rideId: rideID,
                    status: .matched,
                    etaSeconds: driverInfo.etaSeconds,
                    driverName: driverInfo.driverName,
                    driverRating: driverInfo.driverRating,
                    driverVehicle: driverInfo.driverVehicle,
                    driverPlate: driverInfo.driverPlate
                )))
                return .none

            // Searching → Home (cancelled)
            case .path(.element(_, action: .searching(.delegate(.cancelled)))):
                state.path.removeAll()
                return .none

            #if DEBUG
            // ActiveRide → RideComplete (legacy simulation flow)
            case .path(.element(_, action: .activeRide(.delegate(.rideCompleted)))):
                state.path.append(.rideComplete(RideCompleteFeature.State()))
                return .none

            // ActiveRide → Home (cancelled, legacy)
            case .path(.element(_, action: .activeRide(.delegate(.cancelled)))):
                state.path.removeAll()
                return .none
            #endif

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
