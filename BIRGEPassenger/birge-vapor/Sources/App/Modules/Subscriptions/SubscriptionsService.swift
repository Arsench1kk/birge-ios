import Fluent
import Vapor

// TODO(subscription-pivot): Rewrite plans array to solo_corridor/multi_corridor/flex_pack
// with monthly pricing. Current plans (free/lite/standard/pro) are stale.
struct SubscriptionsService {
    let req: Request

    func overview() async throws -> SubscriptionOverviewDTO {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can manage passenger subscriptions")
        }

        let userID = try req.authenticatedUserID
        let subscription = try await PassengerSubscription.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()

        return SubscriptionOverviewDTO(
            currentPlanID: subscription?.planID ?? Self.freePlanID,
            activeSince: Self.formatted(date: subscription?.activatedAt),
            plans: Self.plans
        )
    }

    func activate(_ dto: ActivateSubscriptionRequestDTO) async throws -> ActivateSubscriptionResponseDTO {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can manage passenger subscriptions")
        }

        guard Self.plans.contains(where: { $0.id == dto.planID }) else {
            throw Abort(.badRequest, reason: "Unknown subscription plan")
        }

        let userID = try req.authenticatedUserID
        let subscription = try await PassengerSubscription.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() ?? PassengerSubscription(userID: userID, planID: dto.planID)

        subscription.planID = dto.planID
        try await subscription.save(on: req.db)

        return ActivateSubscriptionResponseDTO(
            currentPlanID: subscription.planID,
            activeSince: Self.formatted(date: subscription.activatedAt),
            message: "Subscription activated"
        )
    }

    private static func formatted(date: Date?) -> String {
        guard let date else { return "Сегодня" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    private static let freePlanID = "free"

    static let plans: [SubscriptionPlanDTO] = [
        SubscriptionPlanDTO(
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
        ),
        SubscriptionPlanDTO(
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
        SubscriptionPlanDTO(
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
        SubscriptionPlanDTO(
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
