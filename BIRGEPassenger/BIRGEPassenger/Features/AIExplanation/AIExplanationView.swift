import ComposableArchitecture
import SwiftUI

@ViewAction(for: AIExplanationFeature.self)
struct AIExplanationView: View {
    @Bindable var store: StoreOf<AIExplanationFeature>

    private var savings: Int {
        store.regularTaxiPrice - store.samplePrice
    }

    private var savingsPercent: Int {
        Int((Double(savings) / Double(store.regularTaxiPrice) * 100).rounded())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BIRGELayout.m) {
                hero

                VStack(spacing: BIRGELayout.xs) {
                    stepCard(
                        number: 1,
                        symbol: "point.topleft.down.curvedto.point.bottomright.up",
                        title: "Вы указываете маршруты",
                        body: "Регулярные поездки помогают BIRGE понять район старта, направление, время и повторяемость.",
                        content: { routePreview }
                    )

                    stepCard(
                        number: 2,
                        symbol: "scope",
                        title: "AI ищет похожие паттерны",
                        body: "Мы сравниваем маршруты рядом с вами, учитывая радиус посадки и удобное окно времени.",
                        content: { matchingStats }
                    )

                    stepCard(
                        number: 3,
                        symbol: "person.3.sequence.fill",
                        title: "Создаётся коридор",
                        body: "Система собирает 2-4 пассажиров в один понятный маршрут с фиксированной ценой.",
                        content: { corridorPreview }
                    )

                    stepCard(
                        number: 4,
                        symbol: "chart.line.downtrend.xyaxis",
                        title: "Вы платите меньше",
                        body: "Цена делится между попутчиками, а водитель получает плотный маршрут без лишнего ожидания.",
                        content: { savingsPreview }
                    )
                }

                privacyCard

                BIRGEPrimaryButton(title: "Попробовать коридоры") {
                    send(.tryCorridorsTapped)
                }
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.top, BIRGELayout.s)
            .padding(.bottom, BIRGELayout.xl)
        }
        .background(background)
        .navigationTitle("Как работает AI")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                BIRGEColors.brandPrimary.opacity(0.14),
                BIRGEColors.background,
                BIRGEColors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var hero: some View {
        VStack(spacing: BIRGELayout.s) {
            ZStack {
                Circle()
                    .stroke(BIRGEColors.brandPrimary.opacity(0.22), lineWidth: 2)
                    .frame(width: 92, height: 92)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(width: 70, height: 70)
                    .background(BIRGEColors.brandPrimary.gradient)
                    .clipShape(Circle())
                    .shadow(color: BIRGEColors.brandPrimary.opacity(0.3), radius: 18, y: 8)
            }

            VStack(spacing: BIRGELayout.xxs) {
                Text("Искусственный интеллект BIRGE")
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Подбирает попутчиков автоматически на основе ваших регулярных поездок.")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(BIRGELayout.l)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.05), isInteractive: true)
        .shadow(color: BIRGEColors.brandPrimary.opacity(0.08), radius: 22, y: 10)
    }

    private func stepCard<Content: View>(
        number: Int,
        symbol: String,
        title: String,
        body: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack(spacing: BIRGELayout.xs) {
                ZStack {
                    Circle()
                        .fill(BIRGEColors.brandPrimary)
                        .frame(width: 34, height: 34)
                    Text("\(number)")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textOnBrand)
                }

                Image(systemName: symbol)
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 34, height: 34)
                    .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.07))

                Text(title)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }

            Text(body)
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            content()
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025), isInteractive: true)
    }

    private var routePreview: some View {
        Label(
            "\(store.sampleRoute) · \(store.sampleDeparture) · Пн-Пт",
            systemImage: "calendar.badge.clock"
        )
        .font(BIRGEFonts.captionBold)
        .foregroundStyle(BIRGEColors.brandPrimary)
        .padding(.horizontal, BIRGELayout.xs)
        .padding(.vertical, BIRGELayout.xxs)
        .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.06))
    }

    private var matchingStats: some View {
        HStack(spacing: BIRGELayout.xs) {
            statTile(value: "\(store.radiusMeters)м", label: "радиус", symbol: "location.circle.fill")
            statTile(value: "+/-\(store.timeWindowMinutes) мин", label: "время", symbol: "clock.fill")
            statTile(value: "\(store.analyzedRoutes)", label: "анализов", symbol: "sparkles")
        }
    }

    private func statTile(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: BIRGELayout.xxxs) {
            Image(systemName: symbol)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.brandPrimary)
            Text(value)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textPrimary)
                .minimumScaleFactor(0.82)
                .lineLimit(1)
            Text(label)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BIRGELayout.xs)
        .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.04))
    }

    private var corridorPreview: some View {
        HStack(spacing: BIRGELayout.xs) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("\(store.sampleRoute) · 3 попутчика")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(1)
                Text("\(store.samplePrice)₸ · фиксированная цена")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()

            HStack(spacing: -6) {
                ForEach(["А", "М", "Д"], id: \.self) { initial in
                    Text(initial)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(BIRGEColors.textOnBrand)
                        .frame(width: 26, height: 26)
                        .background(BIRGEColors.brandPrimary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(BIRGEColors.background, lineWidth: 2))
                }
            }
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.04))
    }

    private var savingsPreview: some View {
        VStack(spacing: BIRGELayout.xxs) {
            priceRow(label: "Обычное такси", value: "\(store.regularTaxiPrice)₸", style: .muted)
            priceRow(label: "Коридор BIRGE", value: "\(store.samplePrice)₸", style: .brand)
            priceRow(label: "Экономия", value: "\(savings)₸ (\(savingsPercent)%)", style: .success)
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.button, tint: BIRGEColors.success.opacity(0.04))
    }

    private enum PriceRowStyle {
        case muted
        case brand
        case success
    }

    private func priceRow(label: String, value: String, style: PriceRowStyle) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .strikethrough(style == .muted)
        }
        .font(style == .muted ? BIRGEFonts.caption : BIRGEFonts.captionBold)
        .foregroundStyle(priceRowColor(style))
    }

    private func priceRowColor(_ style: PriceRowStyle) -> Color {
        switch style {
        case .muted:
            return BIRGEColors.textSecondary
        case .brand:
            return BIRGEColors.brandPrimary
        case .success:
            return BIRGEColors.success
        }
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: BIRGELayout.xs) {
            Image(systemName: "lock.shield.fill")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.success)

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Ваши данные в безопасности")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.success)

                Text("Другие пассажиры видят район и точку посадки, но не ваш точный домашний адрес.")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.05))
    }
}

#Preview {
    NavigationStack {
        AIExplanationView(
            store: Store(initialState: AIExplanationFeature.State()) {
                AIExplanationFeature()
            }
        )
    }
}
