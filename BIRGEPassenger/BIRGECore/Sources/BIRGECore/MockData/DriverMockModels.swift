import Foundation

public enum DriverPlanType: String, CaseIterable, Equatable, Sendable {
    case peakStarter = "peak_starter"
    case starter
    case professional
    case premium
}

public enum MockVerificationStatus: String, CaseIterable, Equatable, Sendable {
    case draft
    case pending
    case failed
    case approved
}

public enum MockDocumentStatus: String, CaseIterable, Equatable, Sendable {
    case missing
    case uploaded
    case needsCorrection
    case approved
}

public enum MockDriverCorridorStatus: String, CaseIterable, Equatable, Sendable {
    case scheduled
    case predeparture
    case navigatingToPickup
    case boarding
    case inProgress
    case completed
    case delayed
    case cancelled
}

public enum MockDriverSubscriptionStatus: String, CaseIterable, Equatable, Sendable {
    case notStarted
    case waitingForFirstCorridor
    case active
    case paymentFailed
}

public struct MockDriverProfile: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var phoneNumber: String
    public var firstName: String
    public var lastName: String
    public var serviceArea: String
    public var verificationStatus: MockVerificationStatus

    public init(
        id: UUID,
        phoneNumber: String,
        firstName: String,
        lastName: String,
        serviceArea: String,
        verificationStatus: MockVerificationStatus
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.serviceArea = serviceArea
        self.verificationStatus = verificationStatus
    }
}

public struct MockVehicleProfile: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var make: String
    public var model: String
    public var year: Int
    public var plateNumber: String
    public var seats: Int

    public init(
        id: UUID,
        make: String,
        model: String,
        year: Int,
        plateNumber: String,
        seats: Int
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.plateNumber = plateNumber
        self.seats = seats
    }
}

public struct MockDriverDocument: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var status: MockDocumentStatus

    public init(id: UUID, title: String, status: MockDocumentStatus) {
        self.id = id
        self.title = title
        self.status = status
    }
}

public struct MockDriverPlan: Equatable, Identifiable, Sendable {
    public var id: DriverPlanType { type }
    public var type: DriverPlanType
    public var title: String
    public var monthlyPriceTenge: Int
    public var subtitle: String
    public var paymentStartsAfterFirstCorridor: Bool
    public var includesZeroCommission: Bool
    public var features: [String]

    public init(
        type: DriverPlanType,
        title: String,
        monthlyPriceTenge: Int,
        subtitle: String,
        paymentStartsAfterFirstCorridor: Bool,
        includesZeroCommission: Bool,
        features: [String]
    ) {
        self.type = type
        self.title = title
        self.monthlyPriceTenge = monthlyPriceTenge
        self.subtitle = subtitle
        self.paymentStartsAfterFirstCorridor = paymentStartsAfterFirstCorridor
        self.includesZeroCommission = includesZeroCommission
        self.features = features
    }
}

public struct MockDriverCorridor: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var pickupNode: String
    public var dropoffNode: String
    public var departureWindow: String
    public var passengerCount: Int
    public var estimatedEarningsTenge: Int
    public var status: MockDriverCorridorStatus

    public init(
        id: UUID,
        name: String,
        pickupNode: String,
        dropoffNode: String,
        departureWindow: String,
        passengerCount: Int,
        estimatedEarningsTenge: Int,
        status: MockDriverCorridorStatus
    ) {
        self.id = id
        self.name = name
        self.pickupNode = pickupNode
        self.dropoffNode = dropoffNode
        self.departureWindow = departureWindow
        self.passengerCount = passengerCount
        self.estimatedEarningsTenge = estimatedEarningsTenge
        self.status = status
    }
}

public struct MockDriverEarningsSummary: Equatable, Sendable {
    public var todayTenge: Int
    public var weekTenge: Int
    public var payoutStatus: String

    public init(todayTenge: Int, weekTenge: Int, payoutStatus: String) {
        self.todayTenge = todayTenge
        self.weekTenge = weekTenge
        self.payoutStatus = payoutStatus
    }
}

public struct MockDriverSubscription: Equatable, Sendable {
    public var planType: DriverPlanType
    public var status: MockDriverSubscriptionStatus
    public var firstCorridorActivatedAt: Date?

    public init(
        planType: DriverPlanType,
        status: MockDriverSubscriptionStatus,
        firstCorridorActivatedAt: Date?
    ) {
        self.planType = planType
        self.status = status
        self.firstCorridorActivatedAt = firstCorridorActivatedAt
    }
}
