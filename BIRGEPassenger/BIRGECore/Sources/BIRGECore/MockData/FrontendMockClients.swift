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
    public var saveProfileBasics: @Sendable (_ phoneNumber: String, _ draft: MockPassengerProfileBasicsDraft) async throws -> Void
    public var saveTrustConsent: @Sendable (_ phoneNumber: String, _ draft: MockPassengerConsentDraft) async throws -> Void
    public var updateOnboardingProgress: @Sendable (_ phoneNumber: String, _ step: PassengerSetupStep?) async throws -> Void

    public init(
        profile: @escaping @Sendable (_ phoneNumber: String) async throws -> MockPassengerProfile,
        onboardingStep: @escaping @Sendable (_ phoneNumber: String) async -> PassengerSetupStep?,
        saveProfileBasics: @escaping @Sendable (_ phoneNumber: String, _ draft: MockPassengerProfileBasicsDraft) async throws -> Void,
        saveTrustConsent: @escaping @Sendable (_ phoneNumber: String, _ draft: MockPassengerConsentDraft) async throws -> Void,
        updateOnboardingProgress: @escaping @Sendable (_ phoneNumber: String, _ step: PassengerSetupStep?) async throws -> Void
    ) {
        self.profile = profile
        self.onboardingStep = onboardingStep
        self.saveProfileBasics = saveProfileBasics
        self.saveTrustConsent = saveTrustConsent
        self.updateOnboardingProgress = updateOnboardingProgress
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
            },
            saveProfileBasics: { _, _ in },
            saveTrustConsent: { _, _ in },
            updateOnboardingProgress: { _, _ in }
        )
    }
}

public struct PassengerRouteClient: Sendable {
    public var draftRoute: @Sendable () async -> MockRouteDraft
    public var searchAddresses: @Sendable (_ query: String) async -> [MockAddressSearchResult]
    public var suggestedPickupNodes: @Sendable (_ address: String) async -> [MockCommuteNode]
    public var suggestedDropoffNodes: @Sendable (_ address: String) async -> [MockCommuteNode]
    public var saveRouteDraft: @Sendable (_ draft: MockRouteDraft) async throws -> MockRouteDraft
    public var homeDashboard: @Sendable () async throws -> MockPassengerHomeDashboard
    public var todayCommutePlan: @Sendable () async throws -> MockTodayCommutePlan
    public var recurringRoutes: @Sendable () async throws -> [MockRecurringRoute]
    public var routeDetail: @Sendable (_ routeID: MockRecurringRoute.ID) async throws -> MockRecurringRoute
    public var pauseRoute: @Sendable (_ routeID: MockRecurringRoute.ID) async throws -> MockRecurringRoute
    public var resumeRoute: @Sendable (_ routeID: MockRecurringRoute.ID) async throws -> MockRecurringRoute
    public var plannedRide: @Sendable (_ rideID: MockPlannedCommuteRide.ID) async throws -> MockPlannedCommuteRide
    public var todayPlannedRide: @Sendable () async throws -> MockPlannedCommuteRide
    public var advancePlannedRideStatus: @Sendable (_ rideID: MockPlannedCommuteRide.ID, _ status: PlannedRideStatus) async throws -> MockPlannedCommuteRide
    public var rideDayTimelines: @Sendable () async -> [MockRideDayTimeline]

    public init(
        draftRoute: @escaping @Sendable () async -> MockRouteDraft,
        searchAddresses: @escaping @Sendable (_ query: String) async -> [MockAddressSearchResult],
        suggestedPickupNodes: @escaping @Sendable (_ address: String) async -> [MockCommuteNode],
        suggestedDropoffNodes: @escaping @Sendable (_ address: String) async -> [MockCommuteNode],
        saveRouteDraft: @escaping @Sendable (_ draft: MockRouteDraft) async throws -> MockRouteDraft,
        homeDashboard: @escaping @Sendable () async throws -> MockPassengerHomeDashboard,
        todayCommutePlan: @escaping @Sendable () async throws -> MockTodayCommutePlan,
        recurringRoutes: @escaping @Sendable () async throws -> [MockRecurringRoute],
        routeDetail: @escaping @Sendable (_ routeID: MockRecurringRoute.ID) async throws -> MockRecurringRoute,
        pauseRoute: @escaping @Sendable (_ routeID: MockRecurringRoute.ID) async throws -> MockRecurringRoute,
        resumeRoute: @escaping @Sendable (_ routeID: MockRecurringRoute.ID) async throws -> MockRecurringRoute,
        plannedRide: @escaping @Sendable (_ rideID: MockPlannedCommuteRide.ID) async throws -> MockPlannedCommuteRide,
        todayPlannedRide: @escaping @Sendable () async throws -> MockPlannedCommuteRide,
        advancePlannedRideStatus: @escaping @Sendable (_ rideID: MockPlannedCommuteRide.ID, _ status: PlannedRideStatus) async throws -> MockPlannedCommuteRide,
        rideDayTimelines: @escaping @Sendable () async -> [MockRideDayTimeline]
    ) {
        self.draftRoute = draftRoute
        self.searchAddresses = searchAddresses
        self.suggestedPickupNodes = suggestedPickupNodes
        self.suggestedDropoffNodes = suggestedDropoffNodes
        self.saveRouteDraft = saveRouteDraft
        self.homeDashboard = homeDashboard
        self.todayCommutePlan = todayCommutePlan
        self.recurringRoutes = recurringRoutes
        self.routeDetail = routeDetail
        self.pauseRoute = pauseRoute
        self.resumeRoute = resumeRoute
        self.plannedRide = plannedRide
        self.todayPlannedRide = todayPlannedRide
        self.advancePlannedRideStatus = advancePlannedRideStatus
        self.rideDayTimelines = rideDayTimelines
    }
}

extension PassengerRouteClient: DependencyKey {
    public static var liveValue: PassengerRouteClient { mockValue }
    public static var testValue: PassengerRouteClient { mockValue }

    public static var mockValue: PassengerRouteClient {
        PassengerRouteClient(
            draftRoute: { BIRGEProductFixtures.Passenger.draftRoute },
            searchAddresses: { query in
                guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
                return BIRGEProductFixtures.Passenger.addressSearchResults.filter {
                    $0.title.localizedCaseInsensitiveContains(query)
                        || $0.subtitle.localizedCaseInsensitiveContains(query)
                        || $0.fullAddress.localizedCaseInsensitiveContains(query)
                }
            },
            suggestedPickupNodes: { _ in BIRGEProductFixtures.Passenger.pickupNodes },
            suggestedDropoffNodes: { _ in BIRGEProductFixtures.Passenger.dropoffNodes },
            saveRouteDraft: { $0 },
            homeDashboard: { BIRGEProductFixtures.Passenger.homeDashboard },
            todayCommutePlan: { BIRGEProductFixtures.Passenger.todayCommutePlan },
            recurringRoutes: { BIRGEProductFixtures.Passenger.recurringRoutes },
            routeDetail: { routeID in
                guard let route = BIRGEProductFixtures.Passenger.recurringRoutes.first(where: { $0.id == routeID }) else {
                    throw MockFrontendError("Route not found.")
                }
                return route
            },
            pauseRoute: { routeID in
                guard var route = BIRGEProductFixtures.Passenger.recurringRoutes.first(where: { $0.id == routeID }) else {
                    throw MockFrontendError("Route not found.")
                }
                route.status = .paused
                return route
            },
            resumeRoute: { routeID in
                guard var route = BIRGEProductFixtures.Passenger.recurringRoutes.first(where: { $0.id == routeID }) else {
                    throw MockFrontendError("Route not found.")
                }
                route.status = .active
                return route
            },
            plannedRide: { rideID in
                guard BIRGEProductFixtures.Passenger.plannedCommuteRide.id == rideID else {
                    throw MockFrontendError("Planned ride not found.")
                }
                return BIRGEProductFixtures.Passenger.plannedCommuteRide
            },
            todayPlannedRide: { BIRGEProductFixtures.Passenger.plannedCommuteRide },
            advancePlannedRideStatus: { rideID, status in
                guard BIRGEProductFixtures.Passenger.plannedCommuteRide.id == rideID else {
                    throw MockFrontendError("Planned ride not found.")
                }
                var ride = BIRGEProductFixtures.Passenger.plannedCommuteRide
                ride.status = status
                ride.completedSummary = status == .completed ? BIRGEProductFixtures.Passenger.completedCommuteSummary : nil
                ride.edgeCase = BIRGEProductFixtures.Passenger.rideDayEdgeCases[status]
                return ride
            },
            rideDayTimelines: { BIRGEProductFixtures.Passenger.rideDayTimelines }
        )
    }
}

public struct PassengerSubscriptionClient: Sendable {
    public var plans: @Sendable () async -> [MockPassengerPlan]
    public var currentPlan: @Sendable () async -> MockMonthlyCommutePlan?
    public var paymentMethods: @Sendable () async -> [MockPaymentMethod]
    public var startMockCheckout: @Sendable (_ planID: PassengerPlanType, _ paymentMethodID: MockPaymentMethod.ID, _ routeDraft: MockRouteDraft?) async throws -> MockCheckoutSession
    public var activateMockSubscription: @Sendable (_ checkoutID: MockCheckoutSession.ID) async throws -> MockMonthlyCommutePlan
    public var billingHistory: @Sendable () async -> [MockBillingReceipt]

    public init(
        plans: @escaping @Sendable () async -> [MockPassengerPlan],
        currentPlan: @escaping @Sendable () async -> MockMonthlyCommutePlan?,
        paymentMethods: @escaping @Sendable () async -> [MockPaymentMethod],
        startMockCheckout: @escaping @Sendable (_ planID: PassengerPlanType, _ paymentMethodID: MockPaymentMethod.ID, _ routeDraft: MockRouteDraft?) async throws -> MockCheckoutSession,
        activateMockSubscription: @escaping @Sendable (_ checkoutID: MockCheckoutSession.ID) async throws -> MockMonthlyCommutePlan,
        billingHistory: @escaping @Sendable () async -> [MockBillingReceipt]
    ) {
        self.plans = plans
        self.currentPlan = currentPlan
        self.paymentMethods = paymentMethods
        self.startMockCheckout = startMockCheckout
        self.activateMockSubscription = activateMockSubscription
        self.billingHistory = billingHistory
    }
}

extension PassengerSubscriptionClient: DependencyKey {
    public static var liveValue: PassengerSubscriptionClient { mockValue }
    public static var testValue: PassengerSubscriptionClient { mockValue }

    public static var mockValue: PassengerSubscriptionClient {
        PassengerSubscriptionClient(
            plans: { BIRGEProductFixtures.Passenger.plans },
            currentPlan: { BIRGEProductFixtures.Passenger.activeCommutePlan },
            paymentMethods: { BIRGEProductFixtures.Passenger.paymentMethods },
            startMockCheckout: { planID, paymentMethodID, routeDraft in
                let amount = BIRGEProductFixtures.Passenger.plans.first { $0.type == planID }?.monthlyPriceTenge ?? 0
                return MockCheckoutSession(
                    id: UUID(uuidString: "71000000-0000-0000-0000-000000000001")!,
                    planType: planID,
                    paymentMethodID: paymentMethodID,
                    routeDraftID: routeDraft?.id,
                    amountTenge: amount,
                    status: "mock_checkout_created"
                )
            },
            activateMockSubscription: { _ in BIRGEProductFixtures.Passenger.activeCommutePlan },
            billingHistory: { BIRGEProductFixtures.Passenger.billingReceipts }
        )
    }
}

public struct PassengerSupportClient: Sendable {
    public var fetchSupportInbox: @Sendable () async throws -> [MockSupportTicket]
    public var fetchTicketDetail: @Sendable (_ ticketID: MockSupportTicket.ID) async throws -> (MockSupportTicket, [MockSupportMessage])
    public var issueCategories: @Sendable () async -> [MockIssueCategory]
    public var submitIssueReport: @Sendable (_ draft: MockIssueReportDraft) async throws -> MockSupportTicket
    public var startLiveSupport: @Sendable (_ context: MockSupportContext?) async throws -> MockLiveSupportSession
    public var fetchSafetyContacts: @Sendable () async throws -> [MockSafetyContact]
    public var saveSafetyContact: @Sendable (_ contact: MockSafetyContact) async throws -> MockSafetyContact
    public var removeSafetyContact: @Sendable (_ contactID: MockSafetyContact.ID) async throws -> Void
    public var createShareStatusSession: @Sendable (_ context: MockSupportContext?) async throws -> MockShareStatusSession

    public init(
        fetchSupportInbox: @escaping @Sendable () async throws -> [MockSupportTicket],
        fetchTicketDetail: @escaping @Sendable (_ ticketID: MockSupportTicket.ID) async throws -> (MockSupportTicket, [MockSupportMessage]),
        issueCategories: @escaping @Sendable () async -> [MockIssueCategory],
        submitIssueReport: @escaping @Sendable (_ draft: MockIssueReportDraft) async throws -> MockSupportTicket,
        startLiveSupport: @escaping @Sendable (_ context: MockSupportContext?) async throws -> MockLiveSupportSession,
        fetchSafetyContacts: @escaping @Sendable () async throws -> [MockSafetyContact],
        saveSafetyContact: @escaping @Sendable (_ contact: MockSafetyContact) async throws -> MockSafetyContact,
        removeSafetyContact: @escaping @Sendable (_ contactID: MockSafetyContact.ID) async throws -> Void,
        createShareStatusSession: @escaping @Sendable (_ context: MockSupportContext?) async throws -> MockShareStatusSession
    ) {
        self.fetchSupportInbox = fetchSupportInbox
        self.fetchTicketDetail = fetchTicketDetail
        self.issueCategories = issueCategories
        self.submitIssueReport = submitIssueReport
        self.startLiveSupport = startLiveSupport
        self.fetchSafetyContacts = fetchSafetyContacts
        self.saveSafetyContact = saveSafetyContact
        self.removeSafetyContact = removeSafetyContact
        self.createShareStatusSession = createShareStatusSession
    }
}

extension PassengerSupportClient: DependencyKey {
    public static var liveValue: PassengerSupportClient { mockValue }
    public static var testValue: PassengerSupportClient { mockValue }

    public static var mockValue: PassengerSupportClient {
        PassengerSupportClient(
            fetchSupportInbox: { BIRGEProductFixtures.Passenger.supportTickets },
            fetchTicketDetail: { ticketID in
                guard let ticket = BIRGEProductFixtures.Passenger.supportTickets.first(where: { $0.id == ticketID }) else {
                    throw MockFrontendError("Support ticket not found.")
                }
                let messages = BIRGEProductFixtures.Passenger.supportMessages.filter { $0.ticketID == ticketID }
                return (ticket, messages)
            },
            issueCategories: { BIRGEProductFixtures.Passenger.issueCategories },
            submitIssueReport: { draft in
                let title = BIRGEProductFixtures.Passenger.issueCategories.first { $0.id == draft.categoryID }?.title
                    ?? "Passenger issue"
                return MockSupportTicket(
                    id: UUID(uuidString: "90000000-0000-0000-0000-000000000061")!,
                    title: title,
                    routeID: draft.context?.routeID,
                    plannedRideID: draft.context?.plannedRideID,
                    driverID: draft.context?.driverID,
                    updatedAtLabel: "Now",
                    status: .open
                )
            },
            startLiveSupport: { context in
                var session = BIRGEProductFixtures.Passenger.liveSupportSession
                session.context = context
                return session
            },
            fetchSafetyContacts: { BIRGEProductFixtures.Passenger.safetyContacts },
            saveSafetyContact: { $0 },
            removeSafetyContact: { _ in },
            createShareStatusSession: { context in
                var session = BIRGEProductFixtures.Passenger.shareStatusSession
                session.context = context
                return session
            }
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

    var passengerSupportClient: PassengerSupportClient {
        get { self[PassengerSupportClient.self] }
        set { self[PassengerSupportClient.self] = newValue }
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
