import ComposableArchitecture
import Foundation

// MARK: - SplashFeature

@Reducer
struct SplashFeature {
    @ObservableState
    struct State: Equatable {
        var hasFinished = false
    }

    enum Action: Sendable {
        case onAppear
        case timerFired
        case delegate(Delegate)

        enum Delegate: Sendable {
            case splashFinished
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(for: .seconds(2.0))
                    await send(.timerFired)
                }
            case .timerFired:
                state.hasFinished = true
                return .send(.delegate(.splashFinished))
            case .delegate:
                return .none
            }
        }
    }
}
