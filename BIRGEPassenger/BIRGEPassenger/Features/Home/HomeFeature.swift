import ComposableArchitecture
import SwiftUI

@Reducer struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var corridors: [CorridorOption] = CorridorOption.mock
        var aiMatchCount: Int = 3
        var driverLat: Double = 43.2220
        var driverLng: Double = 76.8512
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View: Sendable {
            case searchBarTapped
            case callTaxiTapped
            case corridorTapped(CorridorOption)
            case showAllCorridorsTapped
            case profileButtonTapped
            case rideHistoryTapped
            case subscriptionTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case openRideRequest
            case openCorridor(CorridorOption)
            case openCorridorList
            case openProfile
            case openRideHistory
            case openSubscription
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.searchBarTapped), .view(.callTaxiTapped):
                return .send(.delegate(.openRideRequest))
            case .view(.corridorTapped(let corridor)):
                return .send(.delegate(.openCorridor(corridor)))
            case .view(.showAllCorridorsTapped):
                return .send(.delegate(.openCorridorList))
            case .view(.profileButtonTapped):
                return .send(.delegate(.openProfile))
            case .view(.rideHistoryTapped):
                return .send(.delegate(.openRideHistory))
            case .view(.subscriptionTapped):
                return .send(.delegate(.openSubscription))
            case .delegate:
                return .none
            }
        }
    }
}
