import Vapor

struct SubscriptionFeatureDTO: Content {
    let title: String
    let subtitle: String
    let symbol: String
    let isIncluded: Bool
}

struct SubscriptionPlanDTO: Content {
    let id: String
    let title: String
    let price: String
    let subtitle: String
    let badge: String?
    let isPopular: Bool
    let features: [SubscriptionFeatureDTO]
}

struct SubscriptionOverviewDTO: Content {
    let currentPlanID: String
    let activeSince: String
    let plans: [SubscriptionPlanDTO]
}

struct ActivateSubscriptionRequestDTO: Content {
    let planID: String
}

struct ActivateSubscriptionResponseDTO: Content {
    let currentPlanID: String
    let activeSince: String
    let message: String
}
