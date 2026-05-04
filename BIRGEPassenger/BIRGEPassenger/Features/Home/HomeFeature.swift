import BIRGECore
import ComposableArchitecture
import SwiftUI

@Reducer struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var corridors: [CorridorOption] = CorridorOption.mock
        var aiMatchCount: Int = 3
        var driverLat: Double = 43.2220
        var driverLng: Double = 76.8512
        var isLoadingCorridors = false
        var corridorError: String?
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case corridorsLoaded(CorridorListResponse)
        case corridorsFailed(String)
        case delegate(Delegate)

        @CasePathable
        enum View: Sendable {
            case onAppear
            case searchBarTapped
            case callTaxiTapped
            case corridorTapped(CorridorOption)
            case showAllCorridorsTapped
            case aiExplanationTapped
            case projectDemoTapped
            case profileButtonTapped
            case rideHistoryTapped
            case subscriptionTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case openRideRequest
            case openCorridor(CorridorOption)
            case openCorridorList
            case openAIExplanation
            case openProjectDemo
            case openProfile
            case openRideHistory
            case openSubscription
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.isLoadingCorridors = true
                state.corridorError = nil
                return .run { send in
                    do {
                        let response = try await apiClient.fetchCorridors()
                        await send(.corridorsLoaded(response))
                    } catch {
                        await send(.corridorsFailed(error.localizedDescription))
                    }
                }

            case .view(.searchBarTapped), .view(.callTaxiTapped):
                return .send(.delegate(.openRideRequest))
            case .view(.corridorTapped(let corridor)):
                return .send(.delegate(.openCorridor(corridor)))
            case .view(.showAllCorridorsTapped):
                return .send(.delegate(.openCorridorList))
            case .view(.aiExplanationTapped):
                return .send(.delegate(.openAIExplanation))
            case .view(.projectDemoTapped):
                return .send(.delegate(.openProjectDemo))
            case .view(.profileButtonTapped):
                return .send(.delegate(.openProfile))
            case .view(.rideHistoryTapped):
                return .send(.delegate(.openRideHistory))
            case .view(.subscriptionTapped):
                return .send(.delegate(.openSubscription))
            case .corridorsLoaded(let response):
                state.isLoadingCorridors = false
                state.corridorError = nil
                state.corridors = Array(response.corridors.map(CorridorOption.init(dto:)).prefix(3))
                state.aiMatchCount = response.corridors.count
                return .none
            case .corridorsFailed(let message):
                state.isLoadingCorridors = false
                state.corridorError = message
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
