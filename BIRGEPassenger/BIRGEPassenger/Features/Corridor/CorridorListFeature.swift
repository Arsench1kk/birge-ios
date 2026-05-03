import ComposableArchitecture

@Reducer
struct CorridorListFeature {
    @ObservableState
    struct State: Equatable {
        var corridors: [CorridorOption] = CorridorOption.mock
        var selectedFilter: Filter = .all
        var aiSummary = "AI нашёл 5 коридоров по вашим маршрутам"

        enum Filter: String, CaseIterable, Equatable, Sendable {
            case all = "Все"
            case morning = "Утро 07-09"
            case evening = "Вечер 17-20"
            case nearby = "Рядом"
            case affordable = "до 1000₸"
        }

        var filteredCorridors: [CorridorOption] {
            switch selectedFilter {
            case .all, .morning, .evening, .nearby:
                return corridors
            case .affordable:
                return corridors.filter { $0.price <= 1000 }
            }
        }
    }

    enum Action: Sendable {
        case filterSelected(State.Filter)
        case corridorTapped(CorridorOption)
        case delegate(Delegate)

        enum Delegate: Sendable {
            case corridorSelected(CorridorOption)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .filterSelected(let filter):
                state.selectedFilter = filter
                return .none

            case .corridorTapped(let corridor):
                return .send(.delegate(.corridorSelected(corridor)))

            case .delegate:
                return .none
            }
        }
    }
}
