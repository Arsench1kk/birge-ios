import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class AppFeatureNavigationTests: XCTestCase {
    func testSplashWithNoMockSessionRoutesToPhoneLogin() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.mockSessionClient = Self.mockSessionClient(session: nil)
        }

        await store.send(.splash(.delegate(.splashFinished)))
        await store.receive(
            \.passengerAuthDecisionResolved,
            PassengerAuthRouting(phoneNumber: nil, decision: .phoneLogin)
        ) {
            $0 = .unauthenticated(OTPFeature.State())
        }
    }

    func testSplashWithCompletePassengerSessionRoutesHome() async {
        let session = MockSession(
            id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000001")!,
            phoneNumber: BIRGEProductFixtures.Phones.activePassenger,
            role: .passenger,
            accessToken: "mock-access"
        )
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.mockSessionClient = Self.mockSessionClient(session: session)
        }

        await store.send(.splash(.delegate(.splashFinished)))
        await store.receive(
            \.passengerAuthDecisionResolved,
            PassengerAuthRouting(phoneNumber: BIRGEProductFixtures.Phones.activePassenger, decision: .home)
        ) {
            $0 = .authenticated(PassengerAppFeature.State())
        }
    }

    func testOTPUnknownPhoneRoutesToRegistrationPlaceholder() async {
        let store = TestStore(initialState: AppFeature.State.unauthenticated(OTPFeature.State())) {
            AppFeature()
        } withDependencies: {
            $0.mockSessionClient = .mockValue
        }

        await store.send(.otp(.delegate(.authenticated(OTPAuthentication(
            role: "passenger",
            phone: BIRGEProductFixtures.Phones.unknownPassenger
        )))))
        await store.receive(
            \.passengerAuthDecisionResolved,
            PassengerAuthRouting(
                phoneNumber: BIRGEProductFixtures.Phones.unknownPassenger,
                decision: .registration
            )
        ) {
            $0 = .needsOnboarding(OnboardingFeature.State(
                phoneNumber: BIRGEProductFixtures.Phones.unknownPassenger,
                passengerSetupStep: .profileBasics
            ))
        }
    }

    func testOTPIncompleteSetupPhoneRoutesToOnboardingPlaceholder() async {
        let store = TestStore(initialState: AppFeature.State.unauthenticated(OTPFeature.State())) {
            AppFeature()
        } withDependencies: {
            $0.mockSessionClient = .mockValue
        }

        await store.send(.otp(.delegate(.authenticated(OTPAuthentication(
            role: "passenger",
            phone: BIRGEProductFixtures.Phones.incompletePassenger
        )))))
        await store.receive(
            \.passengerAuthDecisionResolved,
            PassengerAuthRouting(
                phoneNumber: BIRGEProductFixtures.Phones.incompletePassenger,
                decision: .resumeSetup(.routeDestination)
            )
        ) {
            $0 = .needsOnboarding(OnboardingFeature.State(
                phoneNumber: BIRGEProductFixtures.Phones.incompletePassenger,
                passengerSetupStep: .routeDestination
            ))
        }
    }

    func testOTPCompleteProfileNoRouteRoutesToFirstRouteSetupPlaceholder() async {
        let store = TestStore(initialState: AppFeature.State.unauthenticated(OTPFeature.State())) {
            AppFeature()
        } withDependencies: {
            $0.mockSessionClient = .mockValue
        }

        await store.send(.otp(.delegate(.authenticated(OTPAuthentication(
            role: "passenger",
            phone: BIRGEProductFixtures.Phones.completePassengerNoRoute
        )))))
        await store.receive(
            \.passengerAuthDecisionResolved,
            PassengerAuthRouting(
                phoneNumber: BIRGEProductFixtures.Phones.completePassengerNoRoute,
                decision: .firstRouteSetup
            )
        ) {
            $0 = .needsOnboarding(OnboardingFeature.State(
                phoneNumber: BIRGEProductFixtures.Phones.completePassengerNoRoute,
                initialStep: .firstRouteEntry
            ))
        }
    }

    func testOTPRouteNoPlanRoutesToAuthenticatedSubscriptionPlaceholder() async {
        let store = TestStore(initialState: AppFeature.State.unauthenticated(OTPFeature.State())) {
            AppFeature()
        } withDependencies: {
            $0.mockSessionClient = .mockValue
        }

        await store.send(.otp(.delegate(.authenticated(OTPAuthentication(
            role: "passenger",
            phone: BIRGEProductFixtures.Phones.passengerWithRouteNoPlan
        )))))
        await store.receive(
            \.passengerAuthDecisionResolved,
            PassengerAuthRouting(
                phoneNumber: BIRGEProductFixtures.Phones.passengerWithRouteNoPlan,
                decision: .subscriptionSelection
            )
        ) {
            var passengerState = PassengerAppFeature.State()
            passengerState.path.append(.subscriptions(SubscriptionsFeature.State()))
            $0 = .authenticated(passengerState)
        }

        guard case let .authenticated(passengerState) = store.state else {
            XCTFail("Expected authenticated passenger state")
            return
        }
        guard case .subscriptions = Array(passengerState.path).last else {
            XCTFail("Expected subscriptions placeholder path")
            return
        }
    }

    func testOTPActiveRouteAndPlanRoutesHome() async {
        let store = TestStore(initialState: AppFeature.State.unauthenticated(OTPFeature.State())) {
            AppFeature()
        } withDependencies: {
            $0.mockSessionClient = .mockValue
        }

        await store.send(.otp(.delegate(.authenticated(OTPAuthentication(
            role: "passenger",
            phone: BIRGEProductFixtures.Phones.activePassenger
        )))))
        await store.receive(
            \.passengerAuthDecisionResolved,
            PassengerAuthRouting(phoneNumber: BIRGEProductFixtures.Phones.activePassenger, decision: .home)
        ) {
            $0 = .authenticated(PassengerAppFeature.State())
        }
    }

    func testRouteDraftReadyDelegateRoutesToSubscriptionPlaceholder() async {
        let draft = BIRGEProductFixtures.Passenger.draftRoute
        let store = TestStore(
            initialState: AppFeature.State.needsOnboarding(OnboardingFeature.State(
                phoneNumber: BIRGEProductFixtures.Phones.completePassengerNoRoute,
                initialStep: .firstRouteEntry,
                routeDraft: draft
            ))
        ) {
            AppFeature()
        }

        await store.send(.onboarding(.delegate(.routeDraftReadyForSubscription(draft)))) {
            var passengerState = PassengerAppFeature.State()
            passengerState.path.append(.subscriptions(SubscriptionsFeature.State()))
            $0 = .authenticated(passengerState)
        }
    }

    func testLogoutClearsSessionAndTokensThenReturnsToPhoneLogin() async {
        let deletedKeys = LockIsolated<[String]>([])
        let didClearSession = LockIsolated(false)

        let store = TestStore(
            initialState: AppFeature.State.authenticated(PassengerAppFeature.State())
        ) {
            AppFeature()
        } withDependencies: {
            $0.keychainClient.delete = { key in
                deletedKeys.withValue { $0.append(key) }
            }
            $0.mockSessionClient = Self.mockSessionClient(
                session: MockSession(
                    id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000002")!,
                    phoneNumber: BIRGEProductFixtures.Phones.activePassenger,
                    role: .passenger,
                    accessToken: "mock-access"
                ),
                onClear: {
                    didClearSession.withValue { $0 = true }
                }
            )
        }

        await store.send(.passengerApp(.delegate(.loggedOut))) {
            $0 = .unauthenticated(OTPFeature.State())
        }
        await store.finish()

        XCTAssertEqual(deletedKeys.value, [
            "birge_access_token",
            "birge_refresh_token",
            "birge_user_id"
        ])
        XCTAssertTrue(didClearSession.value)
    }

    private static func mockSessionClient(
        session: MockSession?,
        onClear: @escaping @Sendable () async -> Void = {}
    ) -> MockSessionClient {
        MockSessionClient(
            requestOTP: { _ in },
            verifyOTP: { phoneNumber, _, role in
                MockSession(
                    id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000003")!,
                    phoneNumber: phoneNumber,
                    role: role,
                    accessToken: "mock-access"
                )
            },
            currentSession: { session },
            clearSession: { await onClear() },
            passengerAuthDecision: { phoneNumber in
                PassengerAuthDecision.resolve(
                    record: BIRGEProductFixtures.Passenger.authRecords.first { $0.phoneNumber == phoneNumber }
                )
            },
            driverAuthDecision: { _ in .phoneLogin }
        )
    }
}
