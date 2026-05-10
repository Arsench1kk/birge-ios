import ConcurrencyExtras
import Dependencies
import Foundation

public struct MockFrontendError: Error, Equatable, Sendable, LocalizedError {
    public let message: String

    public var errorDescription: String? { message }

    public init(_ message: String) {
        self.message = message
    }
}

public struct MockSessionClient: Sendable {
    public var requestOTP: @Sendable (_ phoneNumber: String) async throws -> Void
    public var verifyOTP: @Sendable (_ phoneNumber: String, _ code: String, _ role: MockUserRole) async throws -> MockSession
    public var currentSession: @Sendable () async -> MockSession?
    public var clearSession: @Sendable () async -> Void
    public var passengerAuthDecision: @Sendable (_ phoneNumber: String) async -> PassengerAuthDecision
    public var driverAuthDecision: @Sendable (_ phoneNumber: String) async -> DriverAuthDecision

    public init(
        requestOTP: @escaping @Sendable (_ phoneNumber: String) async throws -> Void,
        verifyOTP: @escaping @Sendable (_ phoneNumber: String, _ code: String, _ role: MockUserRole) async throws -> MockSession,
        currentSession: @escaping @Sendable () async -> MockSession?,
        clearSession: @escaping @Sendable () async -> Void,
        passengerAuthDecision: @escaping @Sendable (_ phoneNumber: String) async -> PassengerAuthDecision,
        driverAuthDecision: @escaping @Sendable (_ phoneNumber: String) async -> DriverAuthDecision
    ) {
        self.requestOTP = requestOTP
        self.verifyOTP = verifyOTP
        self.currentSession = currentSession
        self.clearSession = clearSession
        self.passengerAuthDecision = passengerAuthDecision
        self.driverAuthDecision = driverAuthDecision
    }
}

extension MockSessionClient: DependencyKey {
    public static var liveValue: MockSessionClient { mockValue }
    public static var testValue: MockSessionClient { mockValue }

    public static var mockValue: MockSessionClient {
        let session = LockIsolated<MockSession?>(nil)
        return MockSessionClient(
            requestOTP: { _ in },
            verifyOTP: { phoneNumber, code, role in
                guard code == "111111" || code == "123456" else {
                    throw MockFrontendError("Invalid mock OTP code.")
                }
                let mockSession = MockSession(
                    id: UUID(),
                    phoneNumber: phoneNumber,
                    role: role,
                    accessToken: "mock-\(role.rawValue)-access-token"
                )
                session.withValue { $0 = mockSession }
                return mockSession
            },
            currentSession: {
                session.value
            },
            clearSession: {
                session.withValue { $0 = nil }
            },
            passengerAuthDecision: { phoneNumber in
                PassengerAuthDecision.resolve(
                    record: BIRGEProductFixtures.Passenger.authRecords.first { $0.phoneNumber == phoneNumber }
                )
            },
            driverAuthDecision: { phoneNumber in
                DriverAuthDecision.resolve(
                    record: BIRGEProductFixtures.Driver.authRecords.first { $0.phoneNumber == phoneNumber }
                )
            }
        )
    }
}

public struct PassengerProfileClient: Sendable {
    public var profile: @Sendable (_ phoneNumber: String) async throws -> MockPassengerProfile
    public var onboardingStep: @Sendable (_ phoneNumber: String) async -> PassengerSetupStep?

    public init(
        profile: @escaping @Sendable (_ phoneNumber: String) async throws -> MockPassengerProfile,
        onboardingStep: @escaping @Sendable (_ phoneNumber: String) async -> PassengerSetupStep?
    ) {
        self.profile = profile
        self.onboardingStep = onboardingStep
    }
}

extension PassengerProfileClient: DependencyKey {
    public static var liveValue: PassengerProfileClient { mockValue }
    public static var testValue: PassengerProfileClient { mockValue }

    public static var mockValue: PassengerProfileClient {
        PassengerProfileClient(
            profile: { phoneNumber in
                guard let profile = BIRGEProductFixtures.Passenger.profiles.first(where: { $0.phoneNumber == phoneNumber }) else {
                    throw MockFrontendError("Passenger profile not found.")
                }
                return profile
            },
            onboardingStep: { phoneNumber in
                BIRGEProductFixtures.Passenger.authRecords.first { $0.phoneNumber == phoneNumber }?.setupStep
            }
        )
    }
}

public struct PassengerRouteClient: Sendable {
    public var draftRoute: @Sendable () async -> MockRouteDraft
    public var suggestedPickupNodes: @Sendable (_ address: String) async -> [MockCommuteNode]
    public var suggestedDropoffNodes: @Sendable (_ address: String) async -> [MockCommuteNode]
    public var recurringRoutes: @Sendable () async -> [MockRecurringRoute]
    public var rideDayTimelines: @Sendable () async -> [MockRideDayTimeline]

    public init(
        draftRoute: @escaping @Sendable () async -> MockRouteDraft,
        suggestedPickupNodes: @escaping @Sendable (_ address: String) async -> [MockCommuteNode],
        suggestedDropoffNodes: @escaping @Sendable (_ address: String) async -> [MockCommuteNode],
        recurringRoutes: @escaping @Sendable () async -> [MockRecurringRoute],
        rideDayTimelines: @escaping @Sendable () async -> [MockRideDayTimeline]
    ) {
        self.draftRoute = draftRoute
        self.suggestedPickupNodes = suggestedPickupNodes
        self.suggestedDropoffNodes = suggestedDropoffNodes
        self.recurringRoutes = recurringRoutes
        self.rideDayTimelines = rideDayTimelines
    }
}

extension PassengerRouteClient: DependencyKey {
    public static var liveValue: PassengerRouteClient { mockValue }
    public static var testValue: PassengerRouteClient { mockValue }

    public static var mockValue: PassengerRouteClient {
        PassengerRouteClient(
            draftRoute: { BIRGEProductFixtures.Passenger.draftRoute },
            suggestedPickupNodes: { _ in BIRGEProductFixtures.Passenger.pickupNodes },
            suggestedDropoffNodes: { _ in BIRGEProductFixtures.Passenger.dropoffNodes },
            recurringRoutes: { BIRGEProductFixtures.Passenger.recurringRoutes },
            rideDayTimelines: { BIRGEProductFixtures.Passenger.rideDayTimelines }
        )
    }
}

public struct PassengerSubscriptionClient: Sendable {
    public var plans: @Sendable () async -> [MockPassengerPlan]
    public var currentPlan: @Sendable () async -> MockMonthlyCommutePlan?
    public var paymentMethods: @Sendable () async -> [MockPaymentMethod]

    public init(
        plans: @escaping @Sendable () async -> [MockPassengerPlan],
        currentPlan: @escaping @Sendable () async -> MockMonthlyCommutePlan?,
        paymentMethods: @escaping @Sendable () async -> [MockPaymentMethod]
    ) {
        self.plans = plans
        self.currentPlan = currentPlan
        self.paymentMethods = paymentMethods
    }
}

extension PassengerSubscriptionClient: DependencyKey {
    public static var liveValue: PassengerSubscriptionClient { mockValue }
    public static var testValue: PassengerSubscriptionClient { mockValue }

    public static var mockValue: PassengerSubscriptionClient {
        PassengerSubscriptionClient(
            plans: { BIRGEProductFixtures.Passenger.plans },
            currentPlan: { BIRGEProductFixtures.Passenger.activeCommutePlan },
            paymentMethods: { BIRGEProductFixtures.Passenger.paymentMethods }
        )
    }
}

public struct DriverOnboardingClient: Sendable {
    public var profile: @Sendable (_ phoneNumber: String) async throws -> MockDriverProfile
    public var vehicle: @Sendable () async -> MockVehicleProfile
    public var documents: @Sendable () async -> [MockDriverDocument]
    public var onboardingStep: @Sendable (_ phoneNumber: String) async -> DriverOnboardingStep?
    public var verificationStatus: @Sendable (_ phoneNumber: String) async -> MockVerificationStatus

    public init(
        profile: @escaping @Sendable (_ phoneNumber: String) async throws -> MockDriverProfile,
        vehicle: @escaping @Sendable () async -> MockVehicleProfile,
        documents: @escaping @Sendable () async -> [MockDriverDocument],
        onboardingStep: @escaping @Sendable (_ phoneNumber: String) async -> DriverOnboardingStep?,
        verificationStatus: @escaping @Sendable (_ phoneNumber: String) async -> MockVerificationStatus
    ) {
        self.profile = profile
        self.vehicle = vehicle
        self.documents = documents
        self.onboardingStep = onboardingStep
        self.verificationStatus = verificationStatus
    }
}

extension DriverOnboardingClient: DependencyKey {
    public static var liveValue: DriverOnboardingClient { mockValue }
    public static var testValue: DriverOnboardingClient { mockValue }

    public static var mockValue: DriverOnboardingClient {
        DriverOnboardingClient(
            profile: { phoneNumber in
                guard BIRGEProductFixtures.Driver.authRecords.contains(where: { $0.phoneNumber == phoneNumber }) else {
                    throw MockFrontendError("Driver profile not found.")
                }
                return BIRGEProductFixtures.Driver.approvedProfile
            },
            vehicle: { BIRGEProductFixtures.Driver.vehicle },
            documents: { BIRGEProductFixtures.Driver.documents },
            onboardingStep: { phoneNumber in
                BIRGEProductFixtures.Driver.authRecords.first { $0.phoneNumber == phoneNumber }?.onboardingStep
            },
            verificationStatus: { phoneNumber in
                BIRGEProductFixtures.Driver.authRecords.first { $0.phoneNumber == phoneNumber }?.verificationStatus ?? .draft
            }
        )
    }
}

public struct DriverPlanClient: Sendable {
    public var plans: @Sendable () async -> [MockDriverPlan]
    public var subscription: @Sendable () async -> MockDriverSubscription

    public init(
        plans: @escaping @Sendable () async -> [MockDriverPlan],
        subscription: @escaping @Sendable () async -> MockDriverSubscription
    ) {
        self.plans = plans
        self.subscription = subscription
    }
}

extension DriverPlanClient: DependencyKey {
    public static var liveValue: DriverPlanClient { mockValue }
    public static var testValue: DriverPlanClient { mockValue }

    public static var mockValue: DriverPlanClient {
        DriverPlanClient(
            plans: { BIRGEProductFixtures.Driver.plans },
            subscription: { BIRGEProductFixtures.Driver.activeSubscription }
        )
    }
}

public struct DriverCorridorClient: Sendable {
    public var corridors: @Sendable () async -> [MockDriverCorridor]
    public var earningsSummary: @Sendable () async -> MockDriverEarningsSummary

    public init(
        corridors: @escaping @Sendable () async -> [MockDriverCorridor],
        earningsSummary: @escaping @Sendable () async -> MockDriverEarningsSummary
    ) {
        self.corridors = corridors
        self.earningsSummary = earningsSummary
    }
}

extension DriverCorridorClient: DependencyKey {
    public static var liveValue: DriverCorridorClient { mockValue }
    public static var testValue: DriverCorridorClient { mockValue }

    public static var mockValue: DriverCorridorClient {
        DriverCorridorClient(
            corridors: { BIRGEProductFixtures.Driver.corridors },
            earningsSummary: { BIRGEProductFixtures.Driver.earnings }
        )
    }
}

public extension DependencyValues {
    var mockSessionClient: MockSessionClient {
        get { self[MockSessionClient.self] }
        set { self[MockSessionClient.self] = newValue }
    }

    var passengerProfileClient: PassengerProfileClient {
        get { self[PassengerProfileClient.self] }
        set { self[PassengerProfileClient.self] = newValue }
    }

    var passengerRouteClient: PassengerRouteClient {
        get { self[PassengerRouteClient.self] }
        set { self[PassengerRouteClient.self] = newValue }
    }

    var passengerSubscriptionClient: PassengerSubscriptionClient {
        get { self[PassengerSubscriptionClient.self] }
        set { self[PassengerSubscriptionClient.self] = newValue }
    }

    var driverOnboardingClient: DriverOnboardingClient {
        get { self[DriverOnboardingClient.self] }
        set { self[DriverOnboardingClient.self] = newValue }
    }

    var driverPlanClient: DriverPlanClient {
        get { self[DriverPlanClient.self] }
        set { self[DriverPlanClient.self] = newValue }
    }

    var driverCorridorClient: DriverCorridorClient {
        get { self[DriverCorridorClient.self] }
        set { self[DriverCorridorClient.self] = newValue }
    }
}
