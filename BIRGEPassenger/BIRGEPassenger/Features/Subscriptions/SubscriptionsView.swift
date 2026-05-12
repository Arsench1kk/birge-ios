import BIRGECore
import ComposableArchitecture
import SwiftUI

struct SubscriptionsView: View {
    @Bindable var store: StoreOf<SubscriptionsFeature>

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: BIRGELayout.s) {
                    if store.isLoading {
                        ProgressView()
                            .tint(BIRGEColors.brandPrimary)
                            .accessibilityIdentifier("subscription_loading")
                    }

                    if let errorMessage = store.errorMessage {
                        PaymentFailedStateView(message: errorMessage)
                            .accessibilityIdentifier("subscription_error")
                    }

                    checkoutContent

                    if shouldShowSelectionContent {
                        SubscriptionSelectionContent(store: store)
                        PaymentMethodCarousel(store: store)
                        BillingReceiptPreview(receipts: store.billingReceipts)
                    }
                }
                .padding(.horizontal, BIRGELayout.m)
                .padding(.top, BIRGELayout.s)
                .padding(.bottom, BIRGELayout.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            footer
        }
        .background(BIRGEColors.passengerBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await store.send(.onAppear).finish()
        }
    }

    @ViewBuilder
    private var checkoutContent: some View {
        switch store.checkoutStatus {
        case .idle:
            RoutePlanContextCard(routeDraft: store.routeDraft, activeMonthlyPlan: store.activeMonthlyPlan)
        case .loading:
            MockCheckoutSummary(
                title: "Preparing checkout",
                subtitle: "Creating a mock payment session",
                isLoading: true
            )
        case let .ready(checkout):
            MockCheckoutSummary(
                title: "Confirm mock payment",
                subtitle: checkout.status,
                checkout: checkout,
                selectedPlan: store.selectedPlan,
                selectedPaymentMethod: store.selectedPaymentMethod,
                routeDraft: store.routeDraft,
                isLoading: false
            )
        case let .activating(checkout):
            MockCheckoutSummary(
                title: "Activating subscription",
                subtitle: checkout.status,
                checkout: checkout,
                selectedPlan: store.selectedPlan,
                selectedPaymentMethod: store.selectedPaymentMethod,
                routeDraft: store.routeDraft,
                isLoading: true
            )
        case let .succeeded(plan):
            SubscriptionSuccessView(plan: plan, routeDraft: store.routeDraft)
        case let .failed(message):
            PaymentFailedStateView(message: message)
        }
    }

    private var shouldShowSelectionContent: Bool {
        switch store.checkoutStatus {
        case .idle, .failed:
            return true
        case .loading, .ready, .activating, .succeeded:
            return false
        }
    }

    private var footer: some View {
        VStack(spacing: BIRGELayout.xs) {
            switch store.checkoutStatus {
            case .idle:
                primaryFooterButton(title: "Continue", systemImage: "arrow.right", isEnabled: store.canStartCheckout) {
                    store.send(.continueToCheckoutTapped)
                }
                .accessibilityIdentifier("subscription_continue_checkout")

            case .loading, .activating:
                ProgressView()
                    .tint(BIRGEColors.brandPrimary)
                    .frame(height: 54)
                    .accessibilityIdentifier("subscription_checkout_progress")

            case .ready:
                primaryFooterButton(title: "Confirm mock payment", systemImage: "checkmark.seal.fill") {
                    store.send(.confirmMockPaymentTapped)
                }
                .accessibilityIdentifier("subscription_confirm_payment")

            case .succeeded:
                primaryFooterButton(title: "Done", systemImage: "arrow.right") {
                    store.send(.finishActivationTapped)
                }
                .accessibilityIdentifier("subscription_success_done")

            case .failed:
                primaryFooterButton(title: "Try again", systemImage: "arrow.clockwise") {
                    store.send(.retryPaymentTapped)
                }
                .accessibilityIdentifier("subscription_retry_payment")
            }
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.xs)
        .padding(.bottom, BIRGELayout.s)
        .background(BIRGEColors.passengerBackground.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BIRGEColors.borderSubtle)
                .frame(height: 1)
        }
    }

    private func primaryFooterButton(
        title: String,
        systemImage: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: BIRGELayout.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(BIRGEColors.textOnBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isEnabled ? BIRGEColors.brandPrimary : BIRGEColors.textDisabled)
            .clipShape(Capsule())
        }
        .buttonStyle(BIRGEPressableButtonStyle())
        .disabled(!isEnabled)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: BIRGELayout.xs) {
            Button {
                store.send(.closeDetailTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(BIRGEColors.passengerSurfaceElevated)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(BIRGEColors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(BIRGEPressableButtonStyle())
            .accessibilityIdentifier("subscription_close")

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Choose subscription")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("For recurring routes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.xs)
        .padding(.bottom, BIRGELayout.xs)
        .background(BIRGEColors.passengerBackground.opacity(0.94))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BIRGEColors.borderSubtle)
                .frame(height: 1)
        }
    }
}

private struct SubscriptionSelectionContent: View {
    @Bindable var store: StoreOf<SubscriptionsFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            ForEach(store.plans) { plan in
                SubscriptionPlanTile(
                    plan: plan,
                    isSelected: store.selectedPlanType == plan.type
                ) {
                    store.send(.planTapped(plan.type))
                }
                .accessibilityIdentifier("subscription_plan_\(plan.type.rawValue)")
            }
        }
    }
}

private struct SubscriptionPlanTile: View {
    let plan: MockPassengerPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                HStack(alignment: .top, spacing: BIRGELayout.xs) {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        HStack(spacing: BIRGELayout.xxs) {
                            Text(plan.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(BIRGEColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            if plan.isRecommended {
                                Text("Recommended")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(BIRGEColors.textOnBrand)
                                    .padding(.horizontal, BIRGELayout.xxs)
                                    .padding(.vertical, 3)
                                    .background(BIRGEColors.brandPrimary)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(plan.routeAllowanceDescription)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BIRGEColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: BIRGELayout.xs)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(isSelected ? BIRGEColors.brandPrimary : BIRGEColors.borderSubtle)
                }

                Text(formatTenge(plan.monthlyPriceTenge))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)

                HStack(alignment: .top, spacing: BIRGELayout.xxs) {
                    ForEach(plan.features.prefix(3), id: \.self) { feature in
                        FeatureBullet(text: feature)
                    }
                }
            }
            .padding(BIRGELayout.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? BIRGEColors.brandPrimary.opacity(0.06) : BIRGEColors.passengerSurface)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
            .overlay(
                RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                    .stroke(isSelected ? BIRGEColors.brandPrimary.opacity(0.75) : BIRGEColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(BIRGEPressableButtonStyle())
    }
}

private struct FeatureBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            Circle()
                .fill(BIRGEColors.brandPrimary.opacity(0.75))
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RoutePlanContextCard: View {
    let routeDraft: MockRouteDraft?
    let activeMonthlyPlan: MockMonthlyCommutePlan?

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            if let routeDraft {
                RouteStrip(
                    title: routeDraft.displayName,
                    subtitle: "\(routeDraft.schedule.departureWindowStart)-\(routeDraft.schedule.departureWindowEnd)"
                )
                .accessibilityIdentifier("subscription_route_context")
            } else if let activeMonthlyPlan {
                CurrentPlanPass(plan: activeMonthlyPlan)
            } else {
                VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                    Text("Monthly route")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BIRGEColors.textSecondary)
                    Text("Route context will appear after setup.")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(BIRGEColors.textPrimary)
                }
                .padding(BIRGELayout.s)
                .background(BIRGEColors.passengerSurface)
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
                .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusL).stroke(BIRGEColors.borderSubtle, lineWidth: 1))
                .accessibilityIdentifier("subscription_route_context_empty")
            }
        }
    }
}

private struct PaymentMethodCarousel: View {
    @Bindable var store: StoreOf<SubscriptionsFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text("Payment")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BIRGELayout.xs) {
                    ForEach(store.paymentMethods) { method in
                        PaymentMethodTile(
                            method: method,
                            isSelected: store.selectedPaymentMethodID == method.id
                        ) {
                            store.send(.paymentMethodTapped(method.id))
                        }
                        .accessibilityIdentifier("subscription_payment_\(method.id.uuidString)")
                    }
                }
                .padding(.vertical, BIRGELayout.xxxs)
            }
        }
    }
}

private struct PaymentMethodTile: View {
    let method: MockPaymentMethod
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: BIRGELayout.xxs) {
                PaymentMethodMark(type: method.type)

                Text(method.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 92)
            .frame(minHeight: 76)
            .padding(.vertical, BIRGELayout.xxs)
            .background(isSelected ? BIRGEColors.brandPrimary.opacity(0.08) : BIRGEColors.passengerSurface)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
            .overlay(
                RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                    .stroke(isSelected ? BIRGEColors.brandPrimary : BIRGEColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(BIRGEPressableButtonStyle())
    }
}

private struct PaymentMethodMark: View {
    let type: MockPaymentMethodType

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(markForeground)
            .frame(width: 32, height: 32)
            .background(markBackground)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusXS))
            .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusXS).stroke(BIRGEColors.borderSubtle.opacity(type == .kaspi ? 0 : 1), lineWidth: 1))
    }

    private var iconName: String {
        switch type {
        case .applePay:
            return "apple.logo"
        case .savedCard, .card:
            return "creditcard"
        case .kaspi:
            return "k.square.fill"
        }
    }

    private var markBackground: Color {
        switch type {
        case .applePay:
            return BIRGEColors.paymentApplePay
        case .savedCard, .card:
            return BIRGEColors.paymentCard.opacity(0.10)
        case .kaspi:
            return BIRGEColors.paymentKaspi
        }
    }

    private var markForeground: Color {
        switch type {
        case .applePay, .kaspi:
            return BIRGEColors.textOnBrand
        case .savedCard, .card:
            return BIRGEColors.paymentCard
        }
    }
}

private struct MockCheckoutSummary: View {
    let title: String
    let subtitle: String
    var checkout: MockCheckoutSession?
    var selectedPlan: MockPassengerPlan?
    var selectedPaymentMethod: MockPaymentMethod?
    var routeDraft: MockRouteDraft?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(BIRGEColors.brandPrimary)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(BIRGEColors.brandPrimary)
                }
            }

            PassRouteLine()

            if let routeDraft {
                RouteStrip(title: routeDraft.displayName, subtitle: "\(routeDraft.schedule.departureWindowStart)-\(routeDraft.schedule.departureWindowEnd)")
            }

            VStack(spacing: 0) {
                if let selectedPlan {
                    LedgerRow(title: "Plan", value: selectedPlan.title)
                    LedgerRow(title: "Amount", value: formatTenge(selectedPlan.monthlyPriceTenge))
                } else if let checkout {
                    LedgerRow(title: "Amount", value: formatTenge(checkout.amountTenge))
                }

                if let selectedPaymentMethod {
                    LedgerRow(title: "Payment", value: selectedPaymentMethod.title, isLast: true)
                }
            }
            .background(RowListBackground())
        }
        .padding(BIRGELayout.s)
        .background(TicketBackground())
        .accessibilityIdentifier("subscription_checkout_summary")
    }
}

private struct SubscriptionSuccessView: View {
    let plan: MockMonthlyCommutePlan
    let routeDraft: MockRouteDraft?

    var body: some View {
        VStack(alignment: .center, spacing: BIRGELayout.s) {
            ZStack {
                Circle()
                    .fill(BIRGEColors.success.opacity(0.12))
                    .frame(width: 78, height: 78)
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(BIRGEColors.success)
            }

            Text("Subscription active")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)

            PassRouteLine()
                .frame(width: 210)

            VStack(spacing: 0) {
                LedgerRow(title: "Status", value: plan.status)
                LedgerRow(title: "Plan", value: plan.planType.rawValue, isLast: true)
            }
            .background(RowListBackground())

            if let routeDraft {
                RouteStrip(title: routeDraft.displayName, subtitle: "\(routeDraft.schedule.departureWindowStart)-\(routeDraft.schedule.departureWindowEnd)")
            }
        }
        .padding(BIRGELayout.s)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("subscription_activation_success")
    }
}

private struct PaymentFailedStateView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(BIRGEColors.danger)

            Text("Payment did not activate")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)

            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(BIRGELayout.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BIRGEColors.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
        .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusL).stroke(BIRGEColors.danger.opacity(0.22), lineWidth: 1))
        .accessibilityIdentifier("subscription_payment_failed")
    }
}

private struct CurrentPlanPass: View {
    let plan: MockMonthlyCommutePlan

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text("Current plan")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)
            Text(plan.planType.rawValue)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
            LedgerRow(title: "Status", value: plan.status, isLast: true)
        }
        .padding(BIRGELayout.s)
        .background(TicketBackground())
    }
}

private struct BillingReceiptPreview: View {
    let receipts: [MockBillingReceipt]

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text("Billing")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .textCase(.uppercase)

            if receipts.isEmpty {
                Text("No receipts yet")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .padding(BIRGELayout.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BIRGEColors.passengerSurface)
                    .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(receipts.enumerated()), id: \.element.id) { index, receipt in
                        LedgerRow(
                            title: receipt.status,
                            value: formatTenge(receipt.amountTenge),
                            subtitle: receipt.planType.rawValue,
                            isLast: index == receipts.count - 1
                        )
                        .accessibilityIdentifier("subscription_receipt_\(receipt.id.uuidString)")
                    }
                }
                .background(RowListBackground())
            }
        }
    }
}

private struct RouteStrip: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            VStack(spacing: BIRGELayout.xxxs) {
                Circle()
                    .fill(BIRGEColors.brandPrimary)
                    .frame(width: 12, height: 12)
                Rectangle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.30))
                    .frame(width: 2, height: 22)
                Circle()
                    .fill(BIRGEColors.success)
                    .frame(width: 12, height: 12)
            }

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer(minLength: BIRGELayout.xs)
        }
        .padding(BIRGELayout.s)
        .background(BIRGEColors.passengerSurface)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).stroke(BIRGEColors.borderSubtle, lineWidth: 1))
    }
}

private struct PassRouteLine: View {
    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Circle()
                .stroke(BIRGEColors.brandPrimary, lineWidth: 4)
                .frame(width: 14, height: 14)
            Capsule()
                .fill(BIRGEColors.brandPrimary)
                .frame(height: 3)
            Circle()
                .stroke(BIRGEColors.success, lineWidth: 4)
                .frame(width: 14, height: 14)
        }
    }
}

private struct LedgerRow: View {
    let title: String
    let value: String
    var subtitle: String?
    var isLast = false

    var body: some View {
        HStack(alignment: .center, spacing: BIRGELayout.xs) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BIRGEColors.textTertiary)
                }
            }

            Spacer(minLength: BIRGELayout.xs)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(height: 1)
            }
        }
    }
}

private struct TicketBackground: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .fill(BIRGEColors.passengerSurfaceElevated)
                .shadow(color: BIRGEColors.textPrimary.opacity(0.10), radius: 18, y: 10)
            HStack {
                Circle()
                    .fill(BIRGEColors.passengerBackground)
                    .frame(width: 20, height: 20)
                    .offset(x: -10)
                Spacer()
                Circle()
                    .fill(BIRGEColors.passengerBackground)
                    .frame(width: 20, height: 20)
                    .offset(x: 10)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusL).stroke(BIRGEColors.brandPrimary.opacity(0.18), lineWidth: 1))
    }
}

private struct RowListBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(BIRGEColors.passengerBackground)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(height: 1)
            }
    }
}

private func formatTenge(_ amount: Int) -> String {
    "\(amount.formatted(.number.grouping(.automatic))) KZT"
}

#Preview("Selection") {
    NavigationStack {
        SubscriptionsView(
            store: Store(initialState: previewState()) {
                SubscriptionsFeature()
            }
        )
    }
}

#Preview("Checkout") {
    var state = previewState()
    state.checkoutStatus = .ready(BIRGEProductFixtures.Passenger.checkoutSession)
    return NavigationStack {
        SubscriptionsView(
            store: Store(initialState: state) {
                SubscriptionsFeature()
            }
        )
    }
}

#Preview("Failure") {
    var state = previewState()
    state.checkoutStatus = .failed("Mock payment failed.")
    state.errorMessage = "Mock payment failed."
    return NavigationStack {
        SubscriptionsView(
            store: Store(initialState: state) {
                SubscriptionsFeature()
            }
        )
    }
}

#Preview("Success") {
    var state = previewState()
    state.checkoutStatus = .succeeded(BIRGEProductFixtures.Passenger.activeCommutePlan)
    return NavigationStack {
        SubscriptionsView(
            store: Store(initialState: state) {
                SubscriptionsFeature()
            }
        )
    }
}

private func previewState() -> SubscriptionsFeature.State {
    var state = SubscriptionsFeature.State(routeDraft: BIRGEProductFixtures.Passenger.draftRoute)
    state.plans = BIRGEProductFixtures.Passenger.plans
    state.selectedPlanType = .multiCorridor
    state.paymentMethods = BIRGEProductFixtures.Passenger.paymentMethods
    state.selectedPaymentMethodID = BIRGEProductFixtures.Passenger.paymentMethods.first?.id
    state.activeMonthlyPlan = BIRGEProductFixtures.Passenger.activeCommutePlan
    state.billingReceipts = BIRGEProductFixtures.Passenger.billingReceipts
    return state
}
