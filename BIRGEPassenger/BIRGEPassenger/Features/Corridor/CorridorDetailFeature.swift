import ComposableArchitecture

@Reducer
struct CorridorDetailFeature {
    @ObservableState
    struct State: Equatable {
        let corridor: CorridorOption
        var isJoining = false
    }

    enum Action: Sendable {
        case joinTapped
        case joinFinished
        case delegate(Delegate)

        enum Delegate: Sendable {
            case joined
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .joinTapped:
                state.isJoining = true
                return .run { send in
                    try await Task.sleep(for: .seconds(1))
                    await send(.joinFinished)
                    await send(.delegate(.joined))
                }

            case .joinFinished:
                state.isJoining = false
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
