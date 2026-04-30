import ComposableArchitecture

@Reducer struct RideCompleteFeature {
    @ObservableState
    struct State: Equatable {
        var rating: Int = 0
        var selectedTags: Set<String> = []
        var comment: String = ""
        var isCheckmarkVisible: Bool = false

        let tags = ["Чисто в машине", "Пунктуальный",
                    "Вежливый", "Хороший маршрут", "Быстро доехали"]
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View: Sendable {
            case onAppear
            case ratingSelected(Int)
            case tagToggled(String)
            case commentChanged(String)
            case doneTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case done
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.isCheckmarkVisible = true
                return .none
            case .view(.ratingSelected(let stars)):
                state.rating = stars
                return .none
            case .view(.tagToggled(let tag)):
                if state.selectedTags.contains(tag) {
                    state.selectedTags.remove(tag)
                } else {
                    state.selectedTags.insert(tag)
                }
                return .none
            case .view(.commentChanged(let text)):
                state.comment = text
                return .none
            case .view(.doneTapped):
                return .send(.delegate(.done))
            case .delegate:
                return .none
            }
        }
    }
}
