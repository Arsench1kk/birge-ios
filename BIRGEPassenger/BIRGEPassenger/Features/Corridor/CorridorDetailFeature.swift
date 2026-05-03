import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct CorridorDetailFeature {
    @ObservableState
    struct State: Equatable {
        let corridor: CorridorOption
        var isJoining = false
        var errorMessage: String?
    }

    enum Action: Sendable {
        case joinTapped
        case joinFinished
        case joinFailed(String)
        case delegate(Delegate)

        enum Delegate: Sendable {
            case joined
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .joinTapped:
                state.isJoining = true
                state.errorMessage = nil
                let corridorID = state.corridor.id
                return .run { send in
                    do {
                        _ = try await apiClient.bookCorridor(corridorID)
                        await send(.joinFinished)
                        await send(.delegate(.joined))
                    } catch {
                        await send(.joinFailed(error.localizedDescription))
                    }
                }

            case .joinFinished:
                state.isJoining = false
                return .none

            case .joinFailed(let message):
                state.isJoining = false
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
