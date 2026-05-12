import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct SubscriptionsFeature {
    @ObservableState
    struct State: Equatable {
        enum CheckoutStatus: Equatable, Sendable {
            case idle
            case loading
            case ready(MockCheckoutSession)
            case activating(MockCheckoutSession)
            case succeeded(MockMonthlyCommutePlan)
            case failed(String)
        }

        var routeDraft: MockRouteDraft?
        var plans: [MockPassengerPlan] = []
        var selectedPlanType: PassengerPlanType?
        var paymentMethods: [MockPaymentMethod] = []
        var selectedPaymentMethodID: MockPaymentMethod.ID?
        var checkoutStatus: CheckoutStatus = .idle
        var activeMonthlyPlan: MockMonthlyCommutePlan?
        var billingReceipts: [MockBillingReceipt] = []
        var isLoading = false
        var errorMessage: String?

        init(routeDraft: MockRouteDraft? = nil) {
            self.routeDraft = routeDraft
        }

        var selectedPlan: MockPassengerPlan? {
            guard let selectedPlanType else { return nil }
            return plans.first { $0.type == selectedPlanType }
        }

        var selectedPaymentMethod: MockPaymentMethod? {
            guard let selectedPaymentMethodID else { return nil }
            return paymentMethods.first { $0.id == selectedPaymentMethodID }
        }

        var canStartCheckout: Bool {
            selectedPlan != nil && selectedPaymentMethodID != nil && checkoutStatus != .loading
        }

        var canFinishActivation: Bool {
            if case .succeeded = checkoutStatus { return true }
            return false
        }
    }

    @CasePathable
    enum Action: Equatable, Sendable {
        case onAppear
        case subscriptionDataLoaded(
            plans: [MockPassengerPlan],
            paymentMethods: [MockPaymentMethod],
            currentPlan: MockMonthlyCommutePlan?,
            receipts: [MockBillingReceipt]
        )
        case subscriptionDataFailed(String)
        case planTapped(PassengerPlanType)
        case paymentMethodTapped(MockPaymentMethod.ID)
        case continueToCheckoutTapped
        case checkoutStarted(MockCheckoutSession)
        case checkoutFailed(String)
        case confirmMockPaymentTapped
        case activationSucceeded(MockMonthlyCommutePlan)
        case activationFailed(String)
        case retryPaymentTapped
        case finishActivationTapped
        case closeDetailTapped
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable, Sendable {
            case activationFinished
        }
    }

    @Dependency(\.passengerSubscriptionClient) var passengerSubscriptionClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    async let plans = passengerSubscriptionClient.plans()
                    async let paymentMethods = passengerSubscriptionClient.paymentMethods()
                    async let currentPlan = passengerSubscriptionClient.currentPlan()
                    async let receipts = passengerSubscriptionClient.billingHistory()

                    await send(.subscriptionDataLoaded(
                        plans: plans,
                        paymentMethods: paymentMethods,
                        currentPlan: currentPlan,
                        receipts: receipts
                    ))
                }

            case let .subscriptionDataLoaded(plans, paymentMethods, currentPlan, receipts):
                state.isLoading = false
                state.errorMessage = nil
                state.plans = plans
                state.paymentMethods = paymentMethods
                state.activeMonthlyPlan = currentPlan
                state.billingReceipts = receipts
                state.selectedPlanType = plans.first(where: \.isRecommended)?.type ?? plans.first?.type
                state.selectedPaymentMethodID = paymentMethods.first?.id
                state.checkoutStatus = .idle
                return .none

            case let .subscriptionDataFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let .planTapped(planType):
                state.selectedPlanType = planType
                state.checkoutStatus = .idle
                state.errorMessage = nil
                return .none

            case let .paymentMethodTapped(id):
                state.selectedPaymentMethodID = id
                state.checkoutStatus = .idle
                state.errorMessage = nil
                return .none

            case .continueToCheckoutTapped:
                guard let planType = state.selectedPlanType,
                      let paymentMethodID = state.selectedPaymentMethodID else {
                    return .none
                }
                state.checkoutStatus = .loading
                state.errorMessage = nil
                let routeDraft = state.routeDraft
                return .run { send in
                    do {
                        let checkout = try await passengerSubscriptionClient.startMockCheckout(
                            planType,
                            paymentMethodID,
                            routeDraft
                        )
                        await send(.checkoutStarted(checkout))
                    } catch {
                        await send(.checkoutFailed(error.localizedDescription))
                    }
                }

            case let .checkoutStarted(checkout):
                state.checkoutStatus = .ready(checkout)
                return .none

            case let .checkoutFailed(message):
                state.checkoutStatus = .failed(message)
                state.errorMessage = message
                return .none

            case .confirmMockPaymentTapped:
                guard case let .ready(checkout) = state.checkoutStatus else { return .none }
                state.checkoutStatus = .activating(checkout)
                state.errorMessage = nil
                return .run { send in
                    do {
                        let plan = try await passengerSubscriptionClient.activateMockSubscription(checkout.id)
                        await send(.activationSucceeded(plan))
                    } catch {
                        await send(.activationFailed(error.localizedDescription))
                    }
                }

            case let .activationSucceeded(plan):
                state.activeMonthlyPlan = plan
                state.checkoutStatus = .succeeded(plan)
                state.errorMessage = nil
                return .none

            case let .activationFailed(message):
                state.checkoutStatus = .failed(message)
                state.errorMessage = message
                return .none

            case .retryPaymentTapped:
                state.checkoutStatus = .idle
                state.errorMessage = nil
                return .none

            case .finishActivationTapped:
                guard state.canFinishActivation else { return .none }
                return .send(.delegate(.activationFinished))

            case .closeDetailTapped:
                state.checkoutStatus = .idle
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
