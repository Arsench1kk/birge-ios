import Foundation

public enum PassengerAuthDecision: Equatable, Sendable {
    case phoneLogin
    case registration
    case resumeSetup(PassengerSetupStep)
    case firstRouteSetup
    case subscriptionSelection
    case home
}

public enum DriverAuthDecision: Equatable, Sendable {
    case phoneLogin
    case onboarding(DriverOnboardingStep)
    case verificationPending
    case verificationFailed
    case waitingForFirstCorridor
    case home
}

public enum PassengerSetupStep: String, CaseIterable, Equatable, Sendable {
    case profileBasics
    case trustConsent
    case productIntro
    case routeOrigin
    case routeDestination
    case routeSchedule
    case routeReview
    case monthlyPlan
}

public enum DriverOnboardingStep: String, CaseIterable, Equatable, Sendable {
    case profile
    case vehicle
    case documents
    case serviceArea
    case subscriptionPlan
}

public enum MockUserRole: String, Equatable, Sendable {
    case passenger
    case driver
}

public struct MockSession: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var phoneNumber: String
    public var role: MockUserRole
    public var accessToken: String

    public init(
        id: UUID,
        phoneNumber: String,
        role: MockUserRole,
        accessToken: String
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.role = role
        self.accessToken = accessToken
    }
}

public struct MockPassengerAuthRecord: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var phoneNumber: String
    public var setupStep: PassengerSetupStep?
    public var hasCompletedProfile: Bool
    public var hasRecurringRoute: Bool
    public var hasActiveSubscription: Bool

    public init(
        id: UUID,
        phoneNumber: String,
        setupStep: PassengerSetupStep?,
        hasCompletedProfile: Bool,
        hasRecurringRoute: Bool,
        hasActiveSubscription: Bool
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.setupStep = setupStep
        self.hasCompletedProfile = hasCompletedProfile
        self.hasRecurringRoute = hasRecurringRoute
        self.hasActiveSubscription = hasActiveSubscription
    }

    public var authDecision: PassengerAuthDecision {
        if let setupStep {
            return .resumeSetup(setupStep)
        }
        guard hasCompletedProfile else {
            return .registration
        }
        guard hasRecurringRoute else {
            return .firstRouteSetup
        }
        guard hasActiveSubscription else {
            return .subscriptionSelection
        }
        return .home
    }
}

public struct MockDriverAuthRecord: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var phoneNumber: String
    public var onboardingStep: DriverOnboardingStep?
    public var verificationStatus: MockVerificationStatus
    public var hasActiveCorridor: Bool

    public init(
        id: UUID,
        phoneNumber: String,
        onboardingStep: DriverOnboardingStep?,
        verificationStatus: MockVerificationStatus,
        hasActiveCorridor: Bool
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.onboardingStep = onboardingStep
        self.verificationStatus = verificationStatus
        self.hasActiveCorridor = hasActiveCorridor
    }

    public var authDecision: DriverAuthDecision {
        if let onboardingStep {
            return .onboarding(onboardingStep)
        }

        switch verificationStatus {
        case .draft:
            return .onboarding(.profile)
        case .pending:
            return .verificationPending
        case .failed:
            return .verificationFailed
        case .approved:
            return hasActiveCorridor ? .home : .waitingForFirstCorridor
        }
    }
}

public extension PassengerAuthDecision {
    static func resolve(record: MockPassengerAuthRecord?) -> PassengerAuthDecision {
        guard let record else { return .registration }
        return record.authDecision
    }
}

public extension DriverAuthDecision {
    static func resolve(record: MockDriverAuthRecord?) -> DriverAuthDecision {
        guard let record else { return .onboarding(.profile) }
        return record.authDecision
    }
}
