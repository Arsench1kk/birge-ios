import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct SubscriptionsFeature {
    @ObservableState
    struct State: Equatable {
        var currentPlanID = SubscriptionPlan.free.id
        var selectedPlanID: SubscriptionPlan.ID?
        var plans = SubscriptionPlan.all
        var activeSince = "Сегодня"
        var isLoading = false
        var isActivating = false
        var errorMessage: String?

        var currentPlan: SubscriptionPlan {
            plans.first { $0.id == currentPlanID } ?? .free
        }

        var selectedPlan: SubscriptionPlan? {
            guard let selectedPlanID else { return nil }
            return plans.first { $0.id == selectedPlanID }
        }
    }

    enum Action: Equatable, Sendable {
        case onAppear
        case subscriptionsLoaded(SubscriptionOverviewResponse)
        case subscriptionsFailed(String)
        case planTapped(SubscriptionPlan.ID)
        case activateSelectedTapped
        case activationSucceeded(ActivateSubscriptionResponse)
        case activationFailed(String)
        case closeDetailTapped
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
                        let response = try await apiClient.fetchSubscriptions()
                        await send(.subscriptionsLoaded(response))
                    } catch {
                        await send(.subscriptionsFailed(error.localizedDescription))
                    }
                }

            case .subscriptionsLoaded(let response):
                state.isLoading = false
                state.errorMessage = nil
                state.currentPlanID = response.currentPlanID
                state.activeSince = response.activeSince
                state.plans = response.plans.map(SubscriptionPlan.init(dto:))
                return .none

            case .subscriptionsFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .planTapped(let id):
                state.selectedPlanID = id
                return .none

            case .activateSelectedTapped:
                guard let selectedPlanID = state.selectedPlanID else { return .none }
                state.isActivating = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let response = try await apiClient.activateSubscription(selectedPlanID)
                        await send(.activationSucceeded(response))
                    } catch {
                        await send(.activationFailed(error.localizedDescription))
                    }
                }

            case .activationSucceeded(let response):
                state.isActivating = false
                state.currentPlanID = response.currentPlanID
                state.activeSince = response.activeSince
                state.selectedPlanID = nil
                return .none

            case .activationFailed(let message):
                state.isActivating = false
                state.errorMessage = message
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

    nonisolated init(
        id: String,
        title: String,
        price: String,
        subtitle: String,
        badge: String?,
        isPopular: Bool,
        features: [Feature]
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.subtitle = subtitle
        self.badge = badge
        self.isPopular = isPopular
        self.features = features
    }

    nonisolated init(dto: SubscriptionPlanDTO) {
        self.init(
            id: dto.id,
            title: dto.title,
            price: dto.price,
            subtitle: dto.subtitle,
            badge: dto.badge,
            isPopular: dto.isPopular,
            features: dto.features.map(Feature.init(dto:))
        )
    }

    struct Feature: Equatable, Sendable {
        let title: String
        let subtitle: String
        let symbol: String
        let isIncluded: Bool

        nonisolated init(title: String, subtitle: String, symbol: String, isIncluded: Bool) {
            self.title = title
            self.subtitle = subtitle
            self.symbol = symbol
            self.isIncluded = isIncluded
        }

        nonisolated init(dto: SubscriptionFeatureDTO) {
            self.init(
                title: dto.title,
                subtitle: dto.subtitle,
                symbol: dto.symbol,
                isIncluded: dto.isIncluded
            )
        }
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
