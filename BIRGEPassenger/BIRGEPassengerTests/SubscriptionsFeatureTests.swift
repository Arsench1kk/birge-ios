import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class SubscriptionsFeatureTests: XCTestCase {
    func testLoadingPlansSelectsRecommendedMultiCorridor() async {
        let store = TestStore(initialState: SubscriptionsFeature.State()) {
            SubscriptionsFeature()
        } withDependencies: {
            $0.passengerSubscriptionClient = Self.subscriptionClient()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.subscriptionDataLoaded(
            plans: BIRGEProductFixtures.Passenger.plans,
            paymentMethods: BIRGEProductFixtures.Passenger.paymentMethods,
            currentPlan: BIRGEProductFixtures.Passenger.activeCommutePlan,
            receipts: BIRGEProductFixtures.Passenger.billingReceipts
        )) {
            $0.isLoading = false
            $0.plans = BIRGEProductFixtures.Passenger.plans
            $0.paymentMethods = BIRGEProductFixtures.Passenger.paymentMethods
            $0.activeMonthlyPlan = BIRGEProductFixtures.Passenger.activeCommutePlan
            $0.billingReceipts = BIRGEProductFixtures.Passenger.billingReceipts
            $0.selectedPlanType = .multiCorridor
            $0.selectedPaymentMethodID = BIRGEProductFixtures.Passenger.paymentMethods[0].id
            $0.checkoutStatus = .idle
        }
    }

    func testSelectingSoloCorridor() async {
        let store = TestStore(initialState: Self.loadedState()) {
            SubscriptionsFeature()
        }

        await store.send(.planTapped(.soloCorridor)) {
            $0.selectedPlanType = .soloCorridor
            $0.checkoutStatus = .idle
        }
    }

    func testSelectingFlexPack() async {
        let store = TestStore(initialState: Self.loadedState()) {
            SubscriptionsFeature()
        }

        await store.send(.planTapped(.flexPack)) {
            $0.selectedPlanType = .flexPack
            $0.checkoutStatus = .idle
        }
    }

    func testLoadingPaymentMethods() async {
        let store = TestStore(initialState: SubscriptionsFeature.State()) {
            SubscriptionsFeature()
        } withDependencies: {
            $0.passengerSubscriptionClient = Self.subscriptionClient()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.subscriptionDataLoaded(
            plans: BIRGEProductFixtures.Passenger.plans,
            paymentMethods: BIRGEProductFixtures.Passenger.paymentMethods,
            currentPlan: BIRGEProductFixtures.Passenger.activeCommutePlan,
            receipts: BIRGEProductFixtures.Passenger.billingReceipts
        )) {
            $0.isLoading = false
            $0.plans = BIRGEProductFixtures.Passenger.plans
            $0.paymentMethods = BIRGEProductFixtures.Passenger.paymentMethods
            $0.activeMonthlyPlan = BIRGEProductFixtures.Passenger.activeCommutePlan
            $0.billingReceipts = BIRGEProductFixtures.Passenger.billingReceipts
            $0.selectedPlanType = .multiCorridor
            $0.selectedPaymentMethodID = BIRGEProductFixtures.Passenger.paymentMethods[0].id
        }

        XCTAssertTrue(store.state.paymentMethods.contains { $0.type == .applePay })
        XCTAssertTrue(store.state.paymentMethods.contains { $0.type == .savedCard })
        XCTAssertTrue(store.state.paymentMethods.contains { $0.type == .kaspi })
        XCTAssertTrue(store.state.paymentMethods.contains { $0.type == .card })
    }

    func testSelectingPaymentMethod() async {
        let method = BIRGEProductFixtures.Passenger.paymentMethods[1]
        let store = TestStore(initialState: Self.loadedState()) {
            SubscriptionsFeature()
        }

        await store.send(.paymentMethodTapped(method.id)) {
            $0.selectedPaymentMethodID = method.id
            $0.checkoutStatus = .idle
        }
    }

    func testCheckoutStartsWithSelectedPlanAndPaymentMethod() async {
        let checkout = MockCheckoutSession(
            id: UUID(uuidString: "71000000-0000-0000-0000-000000000020")!,
            planType: .multiCorridor,
            paymentMethodID: BIRGEProductFixtures.Passenger.paymentMethods[0].id,
            routeDraftID: BIRGEProductFixtures.Passenger.draftRoute.id,
            amountTenge: 59900,
            status: "mock_checkout_created"
        )
        let requested = LockIsolated<MockCheckoutSession?>(nil)
        let store = TestStore(initialState: Self.loadedState(routeDraft: BIRGEProductFixtures.Passenger.draftRoute)) {
            SubscriptionsFeature()
        } withDependencies: {
            $0.passengerSubscriptionClient = Self.subscriptionClient(
                onStartCheckout: { planID, paymentMethodID, routeDraft in
                    XCTAssertEqual(planID, .multiCorridor)
                    XCTAssertEqual(paymentMethodID, BIRGEProductFixtures.Passenger.paymentMethods[0].id)
                    XCTAssertEqual(routeDraft, BIRGEProductFixtures.Passenger.draftRoute)
                    requested.withValue { $0 = checkout }
                    return checkout
                }
            )
        }

        await store.send(.continueToCheckoutTapped) {
            $0.checkoutStatus = .loading
        }
        await store.receive(.checkoutStarted(checkout)) {
            $0.checkoutStatus = .ready(checkout)
        }

        XCTAssertEqual(requested.value, checkout)
    }

    func testMockActivationSuccessProducesActiveMonthlyPlan() async {
        let checkout = BIRGEProductFixtures.Passenger.checkoutSession
        var state = Self.loadedState()
        state.checkoutStatus = .ready(checkout)

        let store = TestStore(initialState: state) {
            SubscriptionsFeature()
        } withDependencies: {
            $0.passengerSubscriptionClient = Self.subscriptionClient()
        }

        await store.send(.confirmMockPaymentTapped) {
            $0.checkoutStatus = .activating(checkout)
        }
        await store.receive(.activationSucceeded(BIRGEProductFixtures.Passenger.activeCommutePlan)) {
            $0.activeMonthlyPlan = BIRGEProductFixtures.Passenger.activeCommutePlan
            $0.checkoutStatus = .succeeded(BIRGEProductFixtures.Passenger.activeCommutePlan)
            $0.errorMessage = nil
        }
    }

    func testMockActivationFailureShowsRetryState() async {
        let checkout = BIRGEProductFixtures.Passenger.checkoutSession
        var state = Self.loadedState()
        state.checkoutStatus = .ready(checkout)

        let store = TestStore(initialState: state) {
            SubscriptionsFeature()
        } withDependencies: {
            $0.passengerSubscriptionClient = Self.subscriptionClient(
                onActivate: { _ in throw MockFrontendError("Mock payment failed.") }
            )
        }

        await store.send(.confirmMockPaymentTapped) {
            $0.checkoutStatus = .activating(checkout)
        }
        await store.receive(.activationFailed("Mock payment failed.")) {
            $0.checkoutStatus = .failed("Mock payment failed.")
            $0.errorMessage = "Mock payment failed."
        }
    }

    func testRetryClearsErrorAndCanSucceed() async {
        let checkout = BIRGEProductFixtures.Passenger.checkoutSession
        var state = Self.loadedState()
        state.checkoutStatus = .failed("Mock payment failed.")
        state.errorMessage = "Mock payment failed."

        let store = TestStore(initialState: state) {
            SubscriptionsFeature()
        } withDependencies: {
            $0.passengerSubscriptionClient = Self.subscriptionClient()
        }

        await store.send(.retryPaymentTapped) {
            $0.checkoutStatus = .idle
            $0.errorMessage = nil
        }
        await store.send(.continueToCheckoutTapped) {
            $0.checkoutStatus = .loading
        }
        await store.receive(.checkoutStarted(checkout)) {
            $0.checkoutStatus = .ready(checkout)
        }
        await store.send(.confirmMockPaymentTapped) {
            $0.checkoutStatus = .activating(checkout)
        }
        await store.receive(.activationSucceeded(BIRGEProductFixtures.Passenger.activeCommutePlan)) {
            $0.activeMonthlyPlan = BIRGEProductFixtures.Passenger.activeCommutePlan
            $0.checkoutStatus = .succeeded(BIRGEProductFixtures.Passenger.activeCommutePlan)
        }
    }

    func testFinishActivationDelegatesToPassengerHome() async {
        var state = Self.loadedState()
        state.checkoutStatus = .succeeded(BIRGEProductFixtures.Passenger.activeCommutePlan)
        let store = TestStore(initialState: state) {
            SubscriptionsFeature()
        }

        await store.send(.finishActivationTapped)
        await store.receive(.delegate(.activationFinished))
    }

    func testSoloAndMultiDoNotExposePerRidePricing() {
        let plans = BIRGEProductFixtures.Passenger.plans

        XCTAssertFalse(plans.first { $0.type == .soloCorridor }?.includesPerRidePricing ?? true)
        XCTAssertFalse(plans.first { $0.type == .multiCorridor }?.includesPerRidePricing ?? true)
        XCTAssertTrue(plans.first { $0.type == .flexPack }?.includesPerRidePricing ?? false)
    }

    private static func loadedState(routeDraft: MockRouteDraft? = nil) -> SubscriptionsFeature.State {
        var state = SubscriptionsFeature.State(routeDraft: routeDraft)
        state.plans = BIRGEProductFixtures.Passenger.plans
        state.selectedPlanType = .multiCorridor
        state.paymentMethods = BIRGEProductFixtures.Passenger.paymentMethods
        state.selectedPaymentMethodID = BIRGEProductFixtures.Passenger.paymentMethods[0].id
        state.activeMonthlyPlan = BIRGEProductFixtures.Passenger.activeCommutePlan
        state.billingReceipts = BIRGEProductFixtures.Passenger.billingReceipts
        return state
    }

    private static func subscriptionClient(
        onStartCheckout: @escaping @Sendable (PassengerPlanType, MockPaymentMethod.ID, MockRouteDraft?) async throws -> MockCheckoutSession = { _, _, _ in
            BIRGEProductFixtures.Passenger.checkoutSession
        },
        onActivate: @escaping @Sendable (MockCheckoutSession.ID) async throws -> MockMonthlyCommutePlan = { _ in
            BIRGEProductFixtures.Passenger.activeCommutePlan
        }
    ) -> PassengerSubscriptionClient {
        PassengerSubscriptionClient(
            plans: { BIRGEProductFixtures.Passenger.plans },
            currentPlan: { BIRGEProductFixtures.Passenger.activeCommutePlan },
            paymentMethods: { BIRGEProductFixtures.Passenger.paymentMethods },
            startMockCheckout: onStartCheckout,
            activateMockSubscription: onActivate,
            billingHistory: { BIRGEProductFixtures.Passenger.billingReceipts }
        )
    }
}
