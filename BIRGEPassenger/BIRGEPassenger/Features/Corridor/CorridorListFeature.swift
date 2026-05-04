import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct CorridorListFeature {
    @ObservableState
    struct State: Equatable {
        var corridors: [CorridorOption] = CorridorOption.mock
        var selectedFilter: Filter = .all
        var aiSummary = "AI нашёл 5 коридоров по вашим маршрутам"
        var isLoading = false
        var errorMessage: String?

        enum Filter: String, CaseIterable, Equatable, Sendable {
            case all = "Все"
            case morning = "Утро 07-09"
            case evening = "Вечер 17-20"
            case nearby = "Рядом"
            case affordable = "до 1000₸"
        }

        var filteredCorridors: [CorridorOption] {
            switch selectedFilter {
            case .all, .nearby:
                return corridors
            case .morning:
                return corridors.filter { $0.timeOfDay == "morning" }
            case .evening:
                return corridors.filter { $0.timeOfDay == "evening" }
            case .affordable:
                return corridors.filter { $0.price <= 1000 }
            }
        }
    }

    enum Action: Sendable {
        case onAppear
        case filterSelected(State.Filter)
        case corridorTapped(CorridorOption)
        case corridorsLoaded(CorridorListResponse)
        case corridorsFailed(String)
        case delegate(Delegate)

        enum Delegate: Sendable {
            case corridorSelected(CorridorOption)
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let response = try await apiClient.fetchCorridors()
                        await send(.corridorsLoaded(response))
                    } catch {
                        await send(.corridorsFailed(error.localizedDescription))
                    }
                }

            case .filterSelected(let filter):
                state.selectedFilter = filter
                return .none

            case .corridorTapped(let corridor):
                return .send(.delegate(.corridorSelected(corridor)))

            case .corridorsLoaded(let response):
                state.isLoading = false
                state.errorMessage = nil
                state.corridors = response.corridors.map(CorridorOption.init(dto:))
                state.aiSummary = response.aiSummary
                return .none

            case .corridorsFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
