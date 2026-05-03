import ComposableArchitecture
import Foundation

// MARK: - OnboardingFeature

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var currentPage: Int = 0
        let totalPages: Int = 3
    }

    enum Action: Sendable {
        case nextTapped
        case skipTapped
        case pageChanged(Int)
        case delegate(Delegate)

        enum Delegate: Sendable {
            case onboardingFinished
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nextTapped:
                if state.currentPage < state.totalPages - 1 {
                    state.currentPage += 1
                    return .none
                }
                return .send(.delegate(.onboardingFinished))
            case .skipTapped:
                return .send(.delegate(.onboardingFinished))
            case .pageChanged(let page):
                state.currentPage = page
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
