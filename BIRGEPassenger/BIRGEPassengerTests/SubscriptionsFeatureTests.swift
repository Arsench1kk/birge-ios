import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class SubscriptionsFeatureTests: XCTestCase {
    func testLoadsSubscriptions() async {
        let store = TestStore(initialState: SubscriptionsFeature.State()) {
            SubscriptionsFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                fetchSubscriptions: {
                    SubscriptionOverviewResponse(
                        currentPlanID: "standard",
                        activeSince: "3 мая 2026",
                        plans: SubscriptionPlanDTO.defaults
                    )
                }
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.subscriptionsLoaded(
            SubscriptionOverviewResponse(
                currentPlanID: "standard",
                activeSince: "3 мая 2026",
                plans: SubscriptionPlanDTO.defaults
            )
        )) {
            $0.isLoading = false
            $0.currentPlanID = "standard"
            $0.activeSince = "3 мая 2026"
            $0.plans = SubscriptionPlanDTO.defaults.map(SubscriptionPlan.init(dto:))
        }
    }

    func testPlanSelectionAndActivation() async {
        let store = TestStore(initialState: SubscriptionsFeature.State()) {
            SubscriptionsFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                activateSubscription: { planID in
                    ActivateSubscriptionResponse(
                        currentPlanID: planID,
                        activeSince: "3 мая 2026",
                        message: "Subscription activated"
                    )
                },
                createKaspiCheckout: { _, amountTenge, planID in
                    KaspiCheckoutResponse(
                        paymentID: "payment-pro",
                        provider: "kaspi",
                        status: "checkout_created",
                        amountTenge: amountTenge,
                        kaspiDeepLink: "kaspi://pay?plan=\(planID ?? "none")",
                        message: "Open Kaspi"
                    )
                }
            )
        }

        await store.send(.planTapped("pro")) {
            $0.selectedPlanID = "pro"
            $0.paymentCheckout = nil
        }
        await store.send(.activateSelectedTapped) {
            $0.isCheckingOut = true
            $0.errorMessage = nil
            $0.paymentCheckout = nil
        }
        await store.receive(.checkoutCreated(
            KaspiCheckoutResponse(
                paymentID: "payment-pro",
                provider: "kaspi",
                status: "checkout_created",
                amountTenge: 1200,
                kaspiDeepLink: "kaspi://pay?plan=pro",
                message: "Open Kaspi"
            )
        )) {
            $0.isCheckingOut = false
            $0.paymentCheckout = KaspiCheckoutResponse(
                paymentID: "payment-pro",
                provider: "kaspi",
                status: "checkout_created",
                amountTenge: 1200,
                kaspiDeepLink: "kaspi://pay?plan=pro",
                message: "Open Kaspi"
            )
        }
        await store.send(.paymentConfirmedTapped) {
            $0.isActivating = true
            $0.errorMessage = nil
        }
        await store.receive(.activationSucceeded(
            ActivateSubscriptionResponse(
                currentPlanID: "pro",
                activeSince: "3 мая 2026",
                message: "Subscription activated"
            )
        )) {
            $0.isActivating = false
            $0.currentPlanID = "pro"
            $0.activeSince = "3 мая 2026"
            $0.selectedPlanID = nil
            $0.paymentCheckout = nil
        }
    }

    func testCloseDetailClearsSelection() async {
        var state = SubscriptionsFeature.State()
        state.selectedPlanID = "standard"

        let store = TestStore(initialState: state) {
            SubscriptionsFeature()
        }

        await store.send(.closeDetailTapped) {
            $0.selectedPlanID = nil
            $0.paymentCheckout = nil
        }
    }
}
