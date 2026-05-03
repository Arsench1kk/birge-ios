import ComposableArchitecture
import Foundation

@Reducer
struct SubscriptionsFeature {
    @ObservableState
    struct State: Equatable {
        var currentPlanID = SubscriptionPlan.free.id
        var selectedPlanID: SubscriptionPlan.ID?
        var plans = SubscriptionPlan.all

        var currentPlan: SubscriptionPlan {
            plans.first { $0.id == currentPlanID } ?? .free
        }

        var selectedPlan: SubscriptionPlan? {
            guard let selectedPlanID else { return nil }
            return plans.first { $0.id == selectedPlanID }
        }
    }

    enum Action: Equatable, Sendable {
        case planTapped(SubscriptionPlan.ID)
        case activateSelectedTapped
        case closeDetailTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .planTapped(let id):
                state.selectedPlanID = id
                return .none
            case .activateSelectedTapped:
                if let selectedPlanID = state.selectedPlanID {
                    state.currentPlanID = selectedPlanID
                    state.selectedPlanID = nil
                }
                return .none
            case .closeDetailTapped:
                state.selectedPlanID = nil
                return .none
            }
        }
    }
}

struct SubscriptionPlan: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let price: String
    let subtitle: String
    let badge: String?
    let isPopular: Bool
    let features: [Feature]

    struct Feature: Equatable, Sendable {
        let title: String
        let subtitle: String
        let symbol: String
        let isIncluded: Bool
    }

    static let free = SubscriptionPlan(
        id: "free",
        title: "Бесплатно",
        price: "0₸ / месяц",
        subtitle: "Такси on-demand и просмотр доступных коридоров.",
        badge: "Текущий",
        isPopular: false,
        features: [
            .init(title: "Такси On-Demand", subtitle: "Стандартный тариф", symbol: "car.fill", isIncluded: true),
            .init(title: "Просмотр коридоров", subtitle: "Без бронирования подписки", symbol: "map.fill", isIncluded: true),
            .init(title: "Подписка на коридоры", subtitle: "Недоступно", symbol: "person.3.fill", isIncluded: false),
            .init(title: "Приоритет в поиске", subtitle: "Недоступно", symbol: "bolt.fill", isIncluded: false)
        ]
    )

    static let all: [SubscriptionPlan] = [
        .free,
        SubscriptionPlan(
            id: "lite",
            title: "Лайт",
            price: "650₸ / поездка",
            subtitle: "Один регулярный коридор для спокойных будней.",
            badge: nil,
            isPopular: false,
            features: [
                .init(title: "Такси On-Demand", subtitle: "Всегда доступно", symbol: "car.fill", isIncluded: true),
                .init(title: "1 коридор", subtitle: "Для основного маршрута", symbol: "map.circle.fill", isIncluded: true),
                .init(title: "До 10 поездок в день", subtitle: "Хватает для дома и работы", symbol: "calendar.badge.clock", isIncluded: true),
                .init(title: "Приоритет в час пик", subtitle: "Недоступно", symbol: "bolt.fill", isIncluded: false)
            ]
        ),
        SubscriptionPlan(
            id: "standard",
            title: "Стандарт",
            price: "850₸ / поездка",
            subtitle: "Два коридора и стандартный приоритет.",
            badge: nil,
            isPopular: false,
            features: [
                .init(title: "2 коридора", subtitle: "Например работа и учёба", symbol: "map.fill", isIncluded: true),
                .init(title: "До 30 поездок в день", subtitle: "Для активного расписания", symbol: "calendar", isIncluded: true),
                .init(title: "Стандартный приоритет", subtitle: "Быстрее в популярных районах", symbol: "bolt.circle.fill", isIncluded: true),
                .init(title: "Поддержка 24/7", subtitle: "В профессиональном тарифе", symbol: "message.fill", isIncluded: false)
            ]
        ),
        SubscriptionPlan(
            id: "pro",
            title: "Профессионал",
            price: "1 200₸ / поездка",
            subtitle: "Безлимит коридоров, высокий приоритет и поддержка 24/7.",
            badge: "Популярный выбор",
            isPopular: true,
            features: [
                .init(title: "Безлимит коридоров", subtitle: "Все доступные направления", symbol: "infinity", isIncluded: true),
                .init(title: "Безлимит поездок", subtitle: "Без дневных ограничений", symbol: "car.2.fill", isIncluded: true),
                .init(title: "Высокий приоритет", subtitle: "Лучше в час пик", symbol: "bolt.fill", isIncluded: true),
                .init(title: "Поддержка 24/7", subtitle: "Чат и телефон", symbol: "message.fill", isIncluded: true),
                .init(title: "Скидка 10%", subtitle: "На тариф Комфорт", symbol: "gift.fill", isIncluded: true)
            ]
        )
    ]
}
