import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer struct PassengerAppFeature {
    enum RideFlowResetReason: Equatable, Sendable {
        case passengerDeclinedOffer
        case offerExpired
        case searchCancelled
        case rideCancelled
        case rideCompletionDismissed
        #if DEBUG
        case legacyActiveRideCancelled
        #endif
    }

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
        case offerFound(OfferFoundFeature)
        case corridorList(CorridorListFeature)
        case corridorDetail(CorridorDetailFeature)
        case myCorridors(MyCorridorsFeature)
        case aiExplanation(AIExplanationFeature)
        case projectDemo(ProjectDemoFeature)
        case subscriptions(SubscriptionsFeature)
        case plannedRide(PassengerPlannedRideFeature)
        case support(PassengerSupportFeature)
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

        @CasePathable
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

            // Home → fallback taxi
            case .home(.delegate(.openFallbackTaxi)):
                state.openRideRequest()
                return .none

            // Home → route management placeholder
            case .home(.delegate(.openRouteManagement)):
                state.openMyCorridors()
                return .none

            // Home → today planned commute lifecycle
            case .home(.delegate(.openTodayPlannedRide(let segment))):
                state.openPlannedRide(segment)
                return .none
            
            // Home → Profile
            case .home(.delegate(.openProfile)):
                state.openProfile()
                return .none

            // Home → Corridor List
            case .home(.delegate(.openRouteList)):
                state.openCorridorList()
                return .none

            // Home → AI Explanation
            case .home(.delegate(.openAIExplanation)):
                state.openAIExplanation()
                return .none

            // Home → Project Demo
            case .home(.delegate(.openProjectDemo)):
                state.openProjectDemo()
                return .none

            // AI Explanation → Corridor List
            case .path(.element(_, action: .aiExplanation(.delegate(.openCorridorList)))):
                state.openCorridorList()
                return .none

            // Corridor List → Corridor Detail
            case .path(.element(_, action: .corridorList(.delegate(.corridorSelected(let corridor))))):
                state.openCorridorDetail(corridor)
                return .none

            // Home → My Corridors
            case .home(.delegate(.openRideHistory)):
                state.openMyCorridors()
                return .none

            // Home → Subscription
            case .home(.delegate(.openSubscription)):
                state.openSubscriptions()
                return .none

            // Subscription activation → Home
            case .path(.element(_, action: .subscriptions(.delegate(.activationFinished)))):
                state.path.removeAll()
                return .none

            // Planned commute → Home
            case .path(.element(_, action: .plannedRide(.delegate(.back)))),
                 .path(.element(_, action: .plannedRide(.delegate(.done)))):
                state.path.removeAll()
                return .none

            // Planned commute → support and safety foundation
            case .path(.element(_, action: .plannedRide(.delegate(.reportIssue(let rideID))))):
                state.openSupport(mode: .issueReport, rideID: rideID)
                return .none

            case .path(.element(_, action: .plannedRide(.delegate(.support(let rideID))))):
                state.openSupport(mode: .inbox, rideID: rideID)
                return .none

            case .path(.element(_, action: .plannedRide(.delegate(.safety(let rideID))))):
                state.openSupport(mode: .safetyCenter, rideID: rideID)
                return .none

            case .path(.element(_, action: .plannedRide(.delegate(.shareStatus(let rideID))))):
                state.openSupport(mode: .shareStatus, rideID: rideID)
                return .none

            // Support → Home
            case .path(.element(_, action: .support(.delegate(.back)))),
                 .path(.element(_, action: .support(.delegate(.done)))):
                state.path.removeAll()
                return .none

            // RideRequest → Searching
            case .path(.element(_, action: .rideRequest(.delegate(.rideCreated(let rideId))))):
                state.startRideSearch(rideId: rideId)
                return .none

            // RideRequest → Home
            case .path(.element(_, action: .rideRequest(.delegate(.back)))):
                state.dismissRideRequest()
                return .none

            // Searching → Offer found
            case .path(.element(_, action: .searching(.delegate(.rideMatched(let rideID, let driverInfo))))):
                state.showOfferFound(rideID: rideID, driverInfo: driverInfo)
                return .none

            // Offer found → Ride (production flow)
            case .path(.element(_, action: .offerFound(.delegate(.confirmed(let rideID, let driverInfo))))):
                state.showRideAfterOfferConfirmed(rideID: rideID, driverInfo: driverInfo)
                return .none

            // Offer found → Home
            case .path(.element(_, action: .offerFound(.delegate(.declined)))):
                state.resetRideFlow(reason: .passengerDeclinedOffer)
                return .none

            // Offer found → Home
            case .path(.element(_, action: .offerFound(.delegate(.expired)))):
                state.resetRideFlow(reason: .offerExpired)
                return .none

            // Searching → Home (cancelled)
            case .path(.element(_, action: .searching(.delegate(.cancelled)))):
                state.resetRideFlow(reason: .searchCancelled)
                return .none

            #if DEBUG
            // ActiveRide → RideComplete (legacy simulation flow)
            case .path(.element(_, action: .activeRide(.delegate(.rideCompleted)))):
                state.openRideComplete()
                return .none

            // ActiveRide → Home (cancelled, legacy)
            case .path(.element(_, action: .activeRide(.delegate(.cancelled)))):
                state.resetRideFlow(reason: .legacyActiveRideCancelled)
                return .none
            #endif

            // Ride → RideComplete (production flow)
            case .path(.element(_, action: .ride(.delegate(.completed)))):
                state.openRideComplete()
                return .none

            // Ride → Home (cancelled, production flow)
            case .path(.element(_, action: .ride(.delegate(.cancelled)))):
                state.resetRideFlow(reason: .rideCancelled)
                return .none

            // RideComplete → Home
            case .path(.element(_, action: .rideComplete(.delegate(.done)))):
                state.resetRideFlow(reason: .rideCompletionDismissed)
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

    private static func rideState(
        rideID: String,
        driverInfo: SearchingFeature.DriverInfo
    ) -> RideFeature.State {
        RideFeature.State(
            rideId: rideID,
            status: .matched,
            etaSeconds: driverInfo.etaSeconds,
            driverName: driverInfo.driverName,
            driverRating: driverInfo.driverRating,
            driverVehicle: driverInfo.driverVehicle,
            driverPlate: driverInfo.driverPlate
        )
    }
}

private extension PassengerAppFeature.State {
    mutating func openRideRequest() {
        path.append(.rideRequest(RideRequestFeature.State()))
    }

    mutating func openCorridorList() {
        path.append(.corridorList(CorridorListFeature.State()))
    }

    mutating func openCorridorDetail(_ corridor: CorridorOption) {
        path.append(.corridorDetail(CorridorDetailFeature.State(corridor: corridor)))
    }

    mutating func openJoinedCorridorDetail(_ corridor: CorridorOption) {
        path.append(.corridorDetail(CorridorDetailFeature.State(
            corridor: corridor,
            isJoined: true,
            statusMessage: "Вы уже в этом коридоре"
        )))
    }

    mutating func openMyCorridors() {
        path.append(.myCorridors(MyCorridorsFeature.State()))
    }

    mutating func openAIExplanation() {
        path.append(.aiExplanation(AIExplanationFeature.State()))
    }

    mutating func openProjectDemo() {
        path.append(.projectDemo(ProjectDemoFeature.State()))
    }

    mutating func openSubscriptions() {
        path.append(.subscriptions(SubscriptionsFeature.State()))
    }

    mutating func openPlannedRide(_ segment: MockPlannedRideSegment) {
        path.append(.plannedRide(PassengerPlannedRideFeature.State(rideID: segment.id)))
    }

    mutating func openSupport(
        mode: PassengerSupportFeature.State.Mode,
        rideID: MockPlannedCommuteRide.ID?
    ) {
        var context = BIRGEProductFixtures.Passenger.supportContext
        context.plannedRideID = rideID
        path.append(.support(PassengerSupportFeature.State(mode: mode, context: context)))
    }

    mutating func openProfile() {
        path.append(.profile(ProfileFeature.State()))
    }

    mutating func startRideSearch(rideId: String) {
        path.append(.searching(SearchingFeature.State(rideId: rideId)))
    }

    mutating func dismissRideRequest() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    mutating func showOfferFound(
        rideID: String,
        driverInfo: SearchingFeature.DriverInfo
    ) {
        path.append(.offerFound(OfferFoundFeature.State(
            rideId: rideID,
            driverInfo: driverInfo
        )))
    }

    mutating func showRideAfterOfferConfirmed(
        rideID: String,
        driverInfo: SearchingFeature.DriverInfo
    ) {
        guard !path.isEmpty else {
            path.append(.ride(PassengerAppFeature.rideState(
                rideID: rideID,
                driverInfo: driverInfo
            )))
            return
        }

        path.removeLast()
        path.append(.ride(PassengerAppFeature.rideState(
            rideID: rideID,
            driverInfo: driverInfo
        )))
    }

    mutating func openRideComplete() {
        path.append(.rideComplete(RideCompleteFeature.State()))
    }

    mutating func resetRideFlow(reason: PassengerAppFeature.RideFlowResetReason) {
        path.removeAll()
    }
}
