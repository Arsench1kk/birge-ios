import ComposableArchitecture
import Foundation

@Reducer struct SearchingFeature {
    @ObservableState
    struct State: Equatable {
        var secondsElapsed: Int = 0
        var dotsCount: Int = 1
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case delegate(Delegate)
        case timerTick

        @CasePathable
        enum View: Sendable {
            case onAppear
            case cancelTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case driverFound
            case cancelled
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .run { send in
                    for _ in 0..<30 {
                        try await Task.sleep(for: .seconds(1))
                        await send(.timerTick)
                    }
                    await send(.delegate(.driverFound))
                }

            case .timerTick:
                state.secondsElapsed += 1
                state.dotsCount = (state.dotsCount % 3) + 1
                return .none

            case .view(.cancelTapped):
                return .send(.delegate(.cancelled))

            case .delegate:
                return .none
            }
        }
    }
}
