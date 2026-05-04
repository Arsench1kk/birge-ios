import ComposableArchitecture
import Foundation

// MARK: - OnboardingFeature

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var currentPage: Int = 0
        let totalPages: Int = 8
        var origin = "Алатау, пр. Аль-Фараби"
        var destination = "Есентай Парк, 77/8"
        var morningTime = "07:30"
        var eveningTime = "18:00"
        var selectedDays: Set<CommuteDay> = Set(CommuteDay.weekdays)

        var isIntroPage: Bool {
            currentPage < 3
        }

        var canGoBack: Bool {
            currentPage > 0
        }

        var isFinishedPage: Bool {
            currentPage == totalPages - 1
        }
    }

    enum CommuteDay: String, CaseIterable, Equatable, Sendable {
        case monday = "Пн"
        case tuesday = "Вт"
        case wednesday = "Ср"
        case thursday = "Чт"
        case friday = "Пт"
        case saturday = "Сб"
        case sunday = "Вс"

        static let weekdays: [Self] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    }

    enum Action: Equatable, Sendable {
        case nextTapped
        case backTapped
        case skipTapped
        case pageChanged(Int)
        case originChanged(String)
        case destinationChanged(String)
        case originPresetTapped(String)
        case destinationPresetTapped(String)
        case morningTimeSelected(String)
        case eveningTimeSelected(String)
        case dayTapped(CommuteDay)
        case addAnotherRouteTapped
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
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
            case .backTapped:
                if state.currentPage > 0 {
                    state.currentPage -= 1
                }
                return .none
            case .skipTapped:
                return .send(.delegate(.onboardingFinished))
            case .pageChanged(let page):
                state.currentPage = min(max(page, 0), state.totalPages - 1)
                return .none
            case .originChanged(let origin):
                state.origin = origin
                return .none
            case .destinationChanged(let destination):
                state.destination = destination
                return .none
            case .originPresetTapped(let origin):
                state.origin = origin
                return .none
            case .destinationPresetTapped(let destination):
                state.destination = destination
                return .none
            case .morningTimeSelected(let time):
                state.morningTime = time
                return .none
            case .eveningTimeSelected(let time):
                state.eveningTime = time
                return .none
            case .dayTapped(let day):
                if state.selectedDays.contains(day) {
                    state.selectedDays.remove(day)
                } else {
                    state.selectedDays.insert(day)
                }
                return .none
            case .addAnotherRouteTapped:
                state.currentPage = 3
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
