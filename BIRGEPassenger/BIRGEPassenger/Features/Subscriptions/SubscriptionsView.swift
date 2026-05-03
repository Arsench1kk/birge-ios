import BIRGECore
import ComposableArchitecture
import SwiftUI

struct SubscriptionsView: View {
    @Bindable var store: StoreOf<SubscriptionsFeature>

    var body: some View {
        Group {
            if let plan = store.selectedPlan {
                detail(plan)
            } else {
                list
            }
        }
        .background(background)
        .navigationTitle(store.selectedPlan?.title ?? "Подписка")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.send(.onAppear).finish()
        }
        .toolbar {
            if store.selectedPlan != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.closeDetailTapped)
                    } label: {
                        Label("Назад", systemImage: "chevron.left")
                    }
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                BIRGEColors.brandPrimary.opacity(0.12),
                BIRGEColors.background,
                BIRGEColors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BIRGELayout.m) {
                currentPlanCard

                if store.isLoading {
                    loadingCard
                }

                if let message = store.errorMessage {
                    errorCard(message)
                }

                Text("Выберите тариф")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .textCase(.uppercase)

                VStack(spacing: BIRGELayout.xs) {
                    ForEach(store.plans) { plan in
                        planCard(plan)
                    }
                }

                VStack(spacing: BIRGELayout.xxxs) {
                    Text("Тариф меняется с начала следующего месяца")
                    Text("Отменить можно в любой момент")
                }
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, BIRGELayout.xs)
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.top, BIRGELayout.s)
            .padding(.bottom, BIRGELayout.xl)
        }
    }

    private var currentPlanCard: some View {
        HStack(alignment: .top, spacing: BIRGELayout.s) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Ваш тариф")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .textCase(.uppercase)
                Text(store.currentPlan.title)
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("Активен с \(store.activeSince)")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()

            Label("Активен", systemImage: "checkmark.circle.fill")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.success)
                .padding(.horizontal, BIRGELayout.xs)
                .padding(.vertical, BIRGELayout.xxxs)
                .background(BIRGEColors.success.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04), isInteractive: true)
    }

    private var loadingCard: some View {
        Label("Обновляем тарифы", systemImage: "arrow.triangle.2.circlepath")
            .font(BIRGEFonts.bodyMedium)
            .foregroundStyle(BIRGEColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }

    private func errorCard(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(BIRGEFonts.caption)
            .foregroundStyle(BIRGEColors.warning)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.warning.opacity(0.08))
    }

    private func planCard(_ plan: SubscriptionPlan) -> some View {
        Button {
            store.send(.planTapped(plan.id))
        } label: {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                if let badge = plan.badge {
                    Label(badge, systemImage: plan.isPopular ? "star.fill" : "checkmark.circle.fill")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(plan.isPopular ? BIRGEColors.textOnBrand : BIRGEColors.brandPrimary)
                        .padding(.horizontal, BIRGELayout.xs)
                        .padding(.vertical, BIRGELayout.xxxs)
                        .background(plan.isPopular ? BIRGEColors.brandPrimary : BIRGEColors.brandPrimary.opacity(0.1))
                        .clipShape(Capsule())
                }

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(plan.title)
                            .font(BIRGEFonts.title)
                            .foregroundStyle(BIRGEColors.textPrimary)
                        Text(plan.price)
                            .font(BIRGEFonts.subtext)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textTertiary)
                }

                Text(plan.subtitle)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                    ForEach(plan.features.prefix(4), id: \.title) { feature in
                        featureLine(feature)
                    }
                }
            }
            .padding(BIRGELayout.s)
            .liquidGlass(
                .card,
                tint: plan.isPopular ? BIRGEColors.brandPrimary.opacity(0.07) : BIRGEColors.brandPrimary.opacity(0.025),
                isInteractive: true
            )
            .overlay {
                if store.currentPlanID == plan.id {
                    RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                        .stroke(BIRGEColors.brandPrimary.opacity(0.35), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(BIRGEPressableButtonStyle())
    }

    private func featureLine(_ feature: SubscriptionPlan.Feature) -> some View {
        Label {
            Text(feature.title)
                .strikethrough(!feature.isIncluded)
        } icon: {
            Image(systemName: feature.isIncluded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(feature.isIncluded ? BIRGEColors.success : BIRGEColors.textTertiary)
        }
        .font(BIRGEFonts.caption)
        .foregroundStyle(feature.isIncluded ? BIRGEColors.textPrimary : BIRGEColors.textSecondary.opacity(0.6))
    }

    private func detail(_ plan: SubscriptionPlan) -> some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: BIRGELayout.m) {
                    detailHero(plan)

                    Text("Что включено")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .textCase(.uppercase)

                    VStack(spacing: 0) {
                        ForEach(plan.features, id: \.title) { feature in
                            featureRow(feature)
                            if feature.title != plan.features.last?.title {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .padding(BIRGELayout.s)
                    .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025), isInteractive: true)

                    comparisonCard(highlightedPlan: plan)
                }
                .padding(.horizontal, BIRGELayout.m)
                .padding(.top, BIRGELayout.s)
                .padding(.bottom, 150)
            }

            detailCTA(plan)
        }
    }

    private func detailHero(_ plan: SubscriptionPlan) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text(plan.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(plan.price)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textSecondary)
            Text(plan.subtitle)
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)

            HStack {
                ForEach(plan.features.filter(\.isIncluded).prefix(3), id: \.title) { feature in
                    Label(feature.title, systemImage: feature.symbol)
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, BIRGELayout.xs)
                        .padding(.vertical, BIRGELayout.xxxs)
                        .background(BIRGEColors.brandPrimary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BIRGELayout.m)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.06), isInteractive: true)
    }

    private func featureRow(_ feature: SubscriptionPlan.Feature) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: feature.symbol)
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(feature.isIncluded ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(feature.title)
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(feature.subtitle)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()

            Image(systemName: feature.isIncluded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(feature.isIncluded ? BIRGEColors.success : BIRGEColors.textTertiary)
        }
        .padding(.vertical, BIRGELayout.xs)
    }

    private func comparisonCard(highlightedPlan: SubscriptionPlan) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text("Сравнение")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: BIRGELayout.xxs) {
                comparisonRow("Коридоры", free: "0", standard: "2", pro: "∞", highlighted: highlightedPlan.id)
                comparisonRow("Приоритет", free: "Нет", standard: "Базовый", pro: "Высокий", highlighted: highlightedPlan.id)
                comparisonRow("Поддержка", free: "FAQ", standard: "Чат", pro: "24/7", highlighted: highlightedPlan.id)
                comparisonRow("Цена", free: "0₸", standard: "850₸", pro: "1 200₸", highlighted: highlightedPlan.id)
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }

    private func comparisonRow(
        _ title: String,
        free: String,
        standard: String,
        pro: String,
        highlighted: String
    ) -> some View {
        HStack(spacing: BIRGELayout.xxs) {
            Text(title)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .frame(width: 78, alignment: .leading)
            comparisonValue(free, isHighlighted: highlighted == "free")
            comparisonValue(standard, isHighlighted: highlighted == "standard")
            comparisonValue(pro, isHighlighted: highlighted == "pro")
        }
    }

    private func comparisonValue(_ text: String, isHighlighted: Bool) -> some View {
        Text(text)
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(isHighlighted ? BIRGEColors.brandPrimary : BIRGEColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, BIRGELayout.xxs)
            .background(isHighlighted ? BIRGEColors.brandPrimary.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusXS))
            .minimumScaleFactor(0.75)
            .lineLimit(1)
    }

    private func detailCTA(_ plan: SubscriptionPlan) -> some View {
        VStack(spacing: BIRGELayout.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.price.components(separatedBy: " / ").first ?? plan.price)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(BIRGEColors.brandPrimary)
                Text("/ поездка")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Spacer()
                Text("Отменить в любой момент")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            if let checkout = store.paymentCheckout {
                kaspiCheckoutCard(checkout)
            }

            BIRGEPrimaryButton(
                title: primaryTitle(for: plan),
                isLoading: store.isCheckingOut || store.isActivating
            ) {
                if store.paymentCheckout == nil {
                    store.send(.activateSelectedTapped)
                } else {
                    store.send(.paymentConfirmedTapped)
                }
            }
            .disabled(store.currentPlanID == plan.id || store.isCheckingOut || store.isActivating)

            Button("Остаться на \(store.currentPlan.title)") {
                store.send(.closeDetailTapped)
            }
            .disabled(store.isCheckingOut || store.isActivating)
            .font(BIRGEFonts.bodyMedium)
            .foregroundStyle(BIRGEColors.textSecondary)
            .frame(height: 44)
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.s)
        .padding(.bottom, BIRGELayout.l)
        .background(.ultraThinMaterial)
    }

    private func primaryTitle(for plan: SubscriptionPlan) -> String {
        if store.currentPlanID == plan.id {
            return "Тариф уже активен"
        }
        if store.paymentCheckout != nil {
            return "Я оплатил в Kaspi"
        }
        return "Оплатить через Kaspi"
    }

    private func kaspiCheckoutCard(_ checkout: KaspiCheckoutResponse) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "creditcard.fill")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Kaspi checkout готов")
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("\(checkout.amountTenge)₸ · \(checkout.paymentID.prefix(8))")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()

            if let url = URL(string: checkout.kaspiDeepLink) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .frame(width: 40, height: 40)
                        .background(BIRGEColors.brandPrimary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04), isInteractive: true)
    }
}

#Preview {
    NavigationStack {
        SubscriptionsView(
            store: Store(initialState: SubscriptionsFeature.State()) {
                SubscriptionsFeature()
            }
        )
    }
}
