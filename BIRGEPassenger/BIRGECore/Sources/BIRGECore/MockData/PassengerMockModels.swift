import Foundation

public enum PassengerPlanType: String, CaseIterable, Equatable, Sendable {
    case soloCorridor = "solo_corridor"
    case multiCorridor = "multi_corridor"
    case flexPack = "flex_pack"
}

public enum MockRouteStatus: String, CaseIterable, Equatable, Sendable {
    case draft
    case matching
    case waitlist
    case active
    case paused
    case lowDensity
}

public enum MockPaymentMethodType: String, CaseIterable, Equatable, Sendable {
    case applePay
    case savedCard
    case kaspi
    case card
}

public enum MockRideDayStatus: String, CaseIterable, Equatable, Sendable {
    case scheduled
    case driverEnRoute
    case driverArrived
    case boarding
    case inProgress
    case completed
    case driverLate
    case pickupChanged
    case corridorDelayed
    case corridorNotConfirmed
    case fallbackTaxi
}

public enum MockSupportTicketStatus: String, CaseIterable, Equatable, Sendable {
    case open
    case waitingForPassenger
    case resolved
}

public struct MockPassengerProfile: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var phoneNumber: String
    public var displayName: String
    public var isProfileComplete: Bool
    public var hasAcceptedTrustConsent: Bool

    public init(
        id: UUID,
        phoneNumber: String,
        displayName: String,
        isProfileComplete: Bool,
        hasAcceptedTrustConsent: Bool
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.isProfileComplete = isProfileComplete
        self.hasAcceptedTrustConsent = hasAcceptedTrustConsent
    }
}

public struct MockCommuteNode: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var subtitle: String
    public var coordinate: LatLng
    public var walkingMinutes: Int

    public init(
        id: UUID,
        title: String,
        subtitle: String,
        coordinate: LatLng,
        walkingMinutes: Int
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.walkingMinutes = walkingMinutes
    }
}

public struct MockRouteSchedule: Equatable, Sendable {
    public var weekdays: [String]
    public var departureWindowStart: String
    public var departureWindowEnd: String

    public init(
        weekdays: [String],
        departureWindowStart: String,
        departureWindowEnd: String
    ) {
        self.weekdays = weekdays
        self.departureWindowStart = departureWindowStart
        self.departureWindowEnd = departureWindowEnd
    }
}

public struct MockRouteDraft: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var originAddress: String
    public var destinationAddress: String
    public var suggestedPickupNodes: [MockCommuteNode]
    public var suggestedDropoffNodes: [MockCommuteNode]
    public var selectedPickupNodeID: MockCommuteNode.ID?
    public var selectedDropoffNodeID: MockCommuteNode.ID?
    public var schedule: MockRouteSchedule

    public init(
        id: UUID,
        originAddress: String,
        destinationAddress: String,
        suggestedPickupNodes: [MockCommuteNode],
        suggestedDropoffNodes: [MockCommuteNode],
        selectedPickupNodeID: MockCommuteNode.ID?,
        selectedDropoffNodeID: MockCommuteNode.ID?,
        schedule: MockRouteSchedule
    ) {
        self.id = id
        self.originAddress = originAddress
        self.destinationAddress = destinationAddress
        self.suggestedPickupNodes = suggestedPickupNodes
        self.suggestedDropoffNodes = suggestedDropoffNodes
        self.selectedPickupNodeID = selectedPickupNodeID
        self.selectedDropoffNodeID = selectedDropoffNodeID
        self.schedule = schedule
    }
}

public struct MockRecurringRoute: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var originName: String
    public var destinationName: String
    public var pickupNode: MockCommuteNode
    public var dropoffNode: MockCommuteNode
    public var schedule: MockRouteSchedule
    public var status: MockRouteStatus
    public var reliabilityPercent: Int

    public init(
        id: UUID,
        name: String,
        originName: String,
        destinationName: String,
        pickupNode: MockCommuteNode,
        dropoffNode: MockCommuteNode,
        schedule: MockRouteSchedule,
        status: MockRouteStatus,
        reliabilityPercent: Int
    ) {
        self.id = id
        self.name = name
        self.originName = originName
        self.destinationName = destinationName
        self.pickupNode = pickupNode
        self.dropoffNode = dropoffNode
        self.schedule = schedule
        self.status = status
        self.reliabilityPercent = reliabilityPercent
    }
}

public struct MockPassengerPlan: Equatable, Identifiable, Sendable {
    public var id: PassengerPlanType { type }
    public var type: PassengerPlanType
    public var title: String
    public var monthlyPriceTenge: Int
    public var routeAllowanceDescription: String
    public var isRecommended: Bool
    public var includesPerRidePricing: Bool
    public var features: [String]

    public init(
        type: PassengerPlanType,
        title: String,
        monthlyPriceTenge: Int,
        routeAllowanceDescription: String,
        isRecommended: Bool,
        includesPerRidePricing: Bool,
        features: [String]
    ) {
        self.type = type
        self.title = title
        self.monthlyPriceTenge = monthlyPriceTenge
        self.routeAllowanceDescription = routeAllowanceDescription
        self.isRecommended = isRecommended
        self.includesPerRidePricing = includesPerRidePricing
        self.features = features
    }
}

public struct MockMonthlyCommutePlan: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var planType: PassengerPlanType
    public var status: String
    public var coveredRouteIDs: [MockRecurringRoute.ID]
    public var billingPeriodStart: Date
    public var billingPeriodEnd: Date

    public init(
        id: UUID,
        planType: PassengerPlanType,
        status: String,
        coveredRouteIDs: [MockRecurringRoute.ID],
        billingPeriodStart: Date,
        billingPeriodEnd: Date
    ) {
        self.id = id
        self.planType = planType
        self.status = status
        self.coveredRouteIDs = coveredRouteIDs
        self.billingPeriodStart = billingPeriodStart
        self.billingPeriodEnd = billingPeriodEnd
    }
}

public struct MockPaymentMethod: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var type: MockPaymentMethodType
    public var title: String
    public var subtitle: String

    public init(id: UUID, type: MockPaymentMethodType, title: String, subtitle: String) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
    }
}

public struct MockRideDayTimeline: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var routeID: MockRecurringRoute.ID
    public var status: MockRideDayStatus
    public var boardingCode: String?

    public init(
        id: UUID,
        routeID: MockRecurringRoute.ID,
        status: MockRideDayStatus,
        boardingCode: String?
    ) {
        self.id = id
        self.routeID = routeID
        self.status = status
        self.boardingCode = boardingCode
    }
}

public struct MockSupportTicket: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var routeID: MockRecurringRoute.ID?
    public var status: MockSupportTicketStatus

    public init(
        id: UUID,
        title: String,
        routeID: MockRecurringRoute.ID?,
        status: MockSupportTicketStatus
    ) {
        self.id = id
        self.title = title
        self.routeID = routeID
        self.status = status
    }
}
