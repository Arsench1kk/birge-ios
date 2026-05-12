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

public enum PlannedRideStatus: String, CaseIterable, Equatable, Sendable {
    case scheduled
    case driverAssigned
    case driverEnRoute
    case driverArrived
    case boarding
    case inProgress
    case completed
    case delayed
    case replacementAssigned
    case pickupChanged
    case passengerMissedPickup
    case cancelled
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

public struct MockPassengerProfileBasicsDraft: Equatable, Sendable {
    public var fullName: String
    public var city: String
    public var email: String

    public init(fullName: String, city: String, email: String) {
        self.fullName = fullName
        self.city = city
        self.email = email
    }
}

public struct MockPassengerConsentDraft: Equatable, Sendable {
    public var notificationsConsent: Bool
    public var locationConsent: Bool
    public var routePrivacyConsent: Bool

    public init(
        notificationsConsent: Bool,
        locationConsent: Bool,
        routePrivacyConsent: Bool
    ) {
        self.notificationsConsent = notificationsConsent
        self.locationConsent = locationConsent
        self.routePrivacyConsent = routePrivacyConsent
    }
}

public struct MockAddressSearchResult: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var subtitle: String
    public var fullAddress: String
    public var coordinate: LatLng

    public init(
        id: UUID,
        title: String,
        subtitle: String,
        fullAddress: String,
        coordinate: LatLng
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.fullAddress = fullAddress
        self.coordinate = coordinate
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
    public var displayName: String
    public var originAddress: String
    public var destinationAddress: String
    public var suggestedPickupNodes: [MockCommuteNode]
    public var suggestedDropoffNodes: [MockCommuteNode]
    public var selectedPickupNodeID: MockCommuteNode.ID?
    public var selectedDropoffNodeID: MockCommuteNode.ID?
    public var schedule: MockRouteSchedule

    public init(
        id: UUID,
        displayName: String,
        originAddress: String,
        destinationAddress: String,
        suggestedPickupNodes: [MockCommuteNode],
        suggestedDropoffNodes: [MockCommuteNode],
        selectedPickupNodeID: MockCommuteNode.ID?,
        selectedDropoffNodeID: MockCommuteNode.ID?,
        schedule: MockRouteSchedule
    ) {
        self.id = id
        self.displayName = displayName
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

public enum MockTodayCommuteStatus: String, CaseIterable, Equatable, Sendable {
    case planned
    case noCommuteToday
    case routePaused
    case lowMatch
    case waitlist
}

public struct MockPlannedRideSegment: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var routeID: MockRecurringRoute.ID
    public var pickupNode: MockCommuteNode
    public var dropoffNode: MockCommuteNode
    public var departureWindowStart: String
    public var departureWindowEnd: String
    public var rideDayStatus: MockRideDayStatus

    public init(
        id: UUID,
        routeID: MockRecurringRoute.ID,
        pickupNode: MockCommuteNode,
        dropoffNode: MockCommuteNode,
        departureWindowStart: String,
        departureWindowEnd: String,
        rideDayStatus: MockRideDayStatus
    ) {
        self.id = id
        self.routeID = routeID
        self.pickupNode = pickupNode
        self.dropoffNode = dropoffNode
        self.departureWindowStart = departureWindowStart
        self.departureWindowEnd = departureWindowEnd
        self.rideDayStatus = rideDayStatus
    }
}

public struct MockTodayCommutePlan: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var status: MockTodayCommuteStatus
    public var dateLabel: String
    public var nextSegment: MockPlannedRideSegment?

    public init(
        id: UUID,
        status: MockTodayCommuteStatus,
        dateLabel: String,
        nextSegment: MockPlannedRideSegment?
    ) {
        self.id = id
        self.status = status
        self.dateLabel = dateLabel
        self.nextSegment = nextSegment
    }
}

public struct MockPassengerInsight: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var body: String

    public init(id: UUID, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

public struct MockFallbackTaxiOption: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var subtitle: String
    public var estimatedPickupMinutes: Int

    public init(
        id: UUID,
        title: String,
        subtitle: String,
        estimatedPickupMinutes: Int
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.estimatedPickupMinutes = estimatedPickupMinutes
    }
}

public struct MockPassengerHomeDashboard: Equatable, Sendable {
    public var activePlan: MockMonthlyCommutePlan?
    public var recurringRoutes: [MockRecurringRoute]
    public var todayPlan: MockTodayCommutePlan
    public var insights: [MockPassengerInsight]
    public var fallbackTaxi: MockFallbackTaxiOption?

    public init(
        activePlan: MockMonthlyCommutePlan?,
        recurringRoutes: [MockRecurringRoute],
        todayPlan: MockTodayCommutePlan,
        insights: [MockPassengerInsight],
        fallbackTaxi: MockFallbackTaxiOption?
    ) {
        self.activePlan = activePlan
        self.recurringRoutes = recurringRoutes
        self.todayPlan = todayPlan
        self.insights = insights
        self.fallbackTaxi = fallbackTaxi
    }
}

public struct MockRouteStatusDetail: Equatable, Sendable {
    public var title: String
    public var body: String
    public var actionTitle: String
    public var waitlistPosition: Int?

    public init(title: String, body: String, actionTitle: String, waitlistPosition: Int? = nil) {
        self.title = title
        self.body = body
        self.actionTitle = actionTitle
        self.waitlistPosition = waitlistPosition
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

public struct MockCheckoutSession: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var planType: PassengerPlanType
    public var paymentMethodID: MockPaymentMethod.ID
    public var routeDraftID: MockRouteDraft.ID?
    public var amountTenge: Int
    public var status: String

    public init(
        id: UUID,
        planType: PassengerPlanType,
        paymentMethodID: MockPaymentMethod.ID,
        routeDraftID: MockRouteDraft.ID?,
        amountTenge: Int,
        status: String
    ) {
        self.id = id
        self.planType = planType
        self.paymentMethodID = paymentMethodID
        self.routeDraftID = routeDraftID
        self.amountTenge = amountTenge
        self.status = status
    }
}

public struct MockBillingReceipt: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var checkoutID: MockCheckoutSession.ID
    public var planType: PassengerPlanType
    public var amountTenge: Int
    public var issuedAt: Date
    public var status: String

    public init(
        id: UUID,
        checkoutID: MockCheckoutSession.ID,
        planType: PassengerPlanType,
        amountTenge: Int,
        issuedAt: Date,
        status: String
    ) {
        self.id = id
        self.checkoutID = checkoutID
        self.planType = planType
        self.amountTenge = amountTenge
        self.issuedAt = issuedAt
        self.status = status
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
    public var plannedRideID: MockPlannedCommuteRide.ID?
    public var driverID: MockPlannedRideDriver.ID?
    public var updatedAtLabel: String
    public var status: MockSupportTicketStatus

    public init(
        id: UUID,
        title: String,
        routeID: MockRecurringRoute.ID?,
        plannedRideID: MockPlannedCommuteRide.ID? = nil,
        driverID: MockPlannedRideDriver.ID? = nil,
        updatedAtLabel: String = "",
        status: MockSupportTicketStatus
    ) {
        self.id = id
        self.title = title
        self.routeID = routeID
        self.plannedRideID = plannedRideID
        self.driverID = driverID
        self.updatedAtLabel = updatedAtLabel
        self.status = status
    }
}

public struct MockSupportContext: Equatable, Sendable {
    public var plannedRideID: MockPlannedCommuteRide.ID?
    public var routeID: MockRecurringRoute.ID?
    public var driverID: MockPlannedRideDriver.ID?
    public var subscriptionPlanID: PassengerPlanType?
    public var title: String

    public init(
        plannedRideID: MockPlannedCommuteRide.ID? = nil,
        routeID: MockRecurringRoute.ID? = nil,
        driverID: MockPlannedRideDriver.ID? = nil,
        subscriptionPlanID: PassengerPlanType? = nil,
        title: String
    ) {
        self.plannedRideID = plannedRideID
        self.routeID = routeID
        self.driverID = driverID
        self.subscriptionPlanID = subscriptionPlanID
        self.title = title
    }
}

public struct MockSupportMessage: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var ticketID: MockSupportTicket.ID
    public var senderTitle: String
    public var body: String
    public var sentAtLabel: String

    public init(
        id: UUID,
        ticketID: MockSupportTicket.ID,
        senderTitle: String,
        body: String,
        sentAtLabel: String
    ) {
        self.id = id
        self.ticketID = ticketID
        self.senderTitle = senderTitle
        self.body = body
        self.sentAtLabel = sentAtLabel
    }
}

public struct MockIssueCategory: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var contextHint: String

    public init(id: UUID, title: String, contextHint: String) {
        self.id = id
        self.title = title
        self.contextHint = contextHint
    }
}

public struct MockIssueReportDraft: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var context: MockSupportContext?
    public var categoryID: MockIssueCategory.ID?
    public var description: String

    public init(
        id: UUID,
        context: MockSupportContext?,
        categoryID: MockIssueCategory.ID? = nil,
        description: String = ""
    ) {
        self.id = id
        self.context = context
        self.categoryID = categoryID
        self.description = description
    }
}

public struct MockLiveSupportSession: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var context: MockSupportContext?
    public var title: String
    public var status: String

    public init(id: UUID, context: MockSupportContext?, title: String, status: String) {
        self.id = id
        self.context = context
        self.title = title
        self.status = status
    }
}

public struct MockSafetyContact: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var phoneNumber: String
    public var relationship: String

    public init(id: UUID, name: String, phoneNumber: String, relationship: String) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
    }
}

public struct MockSafetyContactDraft: Equatable, Sendable {
    public var id: MockSafetyContact.ID?
    public var name: String
    public var phoneNumber: String
    public var relationship: String

    public init(
        id: MockSafetyContact.ID? = nil,
        name: String = "",
        phoneNumber: String = "",
        relationship: String = ""
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
    }
}

public struct MockShareStatusSession: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var context: MockSupportContext?
    public var title: String
    public var statusText: String
    public var expiresAtLabel: String

    public init(
        id: UUID,
        context: MockSupportContext?,
        title: String,
        statusText: String,
        expiresAtLabel: String
    ) {
        self.id = id
        self.context = context
        self.title = title
        self.statusText = statusText
        self.expiresAtLabel = expiresAtLabel
    }
}

public struct MockPlannedRideDriver: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var displayName: String
    public var rating: Double
    public var phoneLabel: String

    public init(id: UUID, displayName: String, rating: Double, phoneLabel: String) {
        self.id = id
        self.displayName = displayName
        self.rating = rating
        self.phoneLabel = phoneLabel
    }
}

public struct MockPlannedRideVehicle: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var make: String
    public var model: String
    public var plateNumber: String
    public var color: String

    public init(id: UUID, make: String, model: String, plateNumber: String, color: String) {
        self.id = id
        self.make = make
        self.model = model
        self.plateNumber = plateNumber
        self.color = color
    }
}

public struct MockBoardingCode: Equatable, Sendable {
    public var value: String
    public var refreshesInSeconds: Int

    public init(value: String, refreshesInSeconds: Int) {
        self.value = value
        self.refreshesInSeconds = refreshesInSeconds
    }
}

public struct MockRideTimelineItem: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var detail: String
    public var status: PlannedRideStatus

    public init(id: UUID, title: String, detail: String, status: PlannedRideStatus) {
        self.id = id
        self.title = title
        self.detail = detail
        self.status = status
    }
}

public struct MockCompletedCommuteSummary: Equatable, Sendable {
    public var title: String
    public var arrivalText: String
    public var routeSummary: String

    public init(title: String, arrivalText: String, routeSummary: String) {
        self.title = title
        self.arrivalText = arrivalText
        self.routeSummary = routeSummary
    }
}

public struct MockRideDayEdgeCase: Equatable, Sendable {
    public var status: PlannedRideStatus
    public var title: String
    public var body: String
    public var actionTitle: String

    public init(status: PlannedRideStatus, title: String, body: String, actionTitle: String) {
        self.status = status
        self.title = title
        self.body = body
        self.actionTitle = actionTitle
    }
}

public struct MockPlannedCommuteRide: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var routeID: MockRecurringRoute.ID
    public var routeName: String
    public var pickupNode: MockCommuteNode
    public var dropoffNode: MockCommuteNode
    public var departureWindow: String
    public var status: PlannedRideStatus
    public var driver: MockPlannedRideDriver?
    public var vehicle: MockPlannedRideVehicle?
    public var boardingCode: MockBoardingCode?
    public var etaText: String
    public var timeline: [MockRideTimelineItem]
    public var completedSummary: MockCompletedCommuteSummary?
    public var edgeCase: MockRideDayEdgeCase?

    public init(
        id: UUID,
        routeID: MockRecurringRoute.ID,
        routeName: String,
        pickupNode: MockCommuteNode,
        dropoffNode: MockCommuteNode,
        departureWindow: String,
        status: PlannedRideStatus,
        driver: MockPlannedRideDriver?,
        vehicle: MockPlannedRideVehicle?,
        boardingCode: MockBoardingCode?,
        etaText: String,
        timeline: [MockRideTimelineItem],
        completedSummary: MockCompletedCommuteSummary? = nil,
        edgeCase: MockRideDayEdgeCase? = nil
    ) {
        self.id = id
        self.routeID = routeID
        self.routeName = routeName
        self.pickupNode = pickupNode
        self.dropoffNode = dropoffNode
        self.departureWindow = departureWindow
        self.status = status
        self.driver = driver
        self.vehicle = vehicle
        self.boardingCode = boardingCode
        self.etaText = etaText
        self.timeline = timeline
        self.completedSummary = completedSummary
        self.edgeCase = edgeCase
    }
}
