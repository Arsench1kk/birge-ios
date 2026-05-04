import ComposableArchitecture
import SwiftUI

@ViewAction(for: OfferFoundFeature.self)
struct OfferFoundView: View {
    @Bindable var store: StoreOf<OfferFoundFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BIRGEColors.brandPrimary.opacity(0.20),
                    BIRGEColors.brandPrimary.opacity(0.06),
                    BIRGEColors.surfacePrimary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: BIRGELayout.m) {
                    header
                        .padding(.top, BIRGELayout.xl)

                    offerCard

                    timerCard

                    if let errorMessage = store.errorMessage {
                        BIRGEToast(message: errorMessage, style: .error)
                    }

                    actionStack
                        .padding(.bottom, BIRGELayout.l)
                }
                .padding(.horizontal, BIRGELayout.s)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { send(.onAppear) }
        .onDisappear { send(.onDisappear) }
    }

    private var header: some View {
        VStack(spacing: BIRGELayout.xs) {
            BIRGEAIPill("AI нашёл коридор")

            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 68, height: 68)
                .liquidGlass(
                    .pill,
                    tint: BIRGEColors.brandPrimary.opacity(0.08),
                    isInteractive: true
                )
                .scaleEffect(reduceMotion ? 1 : 1.03)

            VStack(spacing: BIRGELayout.xxxs) {
                Text("Совпадение найдено!")
                    .font(BIRGEFonts.heroNumber)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Ваш коридор готов к отправлению")
                    .font(BIRGEFonts.body)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var offerCard: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            routeSection

            Divider()
                .background(BIRGEColors.brandPrimary.opacity(0.10))

            detailGrid

            Divider()
                .background(BIRGEColors.brandPrimary.opacity(0.10))

            companionsSection

            HStack {
                Spacer()
                BIRGEMatchBadge(store.matchPercent)
                Spacer()
            }
        }
        .padding(BIRGELayout.m)
        .liquidGlass(
            .card,
            tint: BIRGEColors.brandPrimary.opacity(0.055),
            isInteractive: true
        )
        .overlay(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .stroke(BIRGEColors.brandPrimary.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: BIRGEColors.brandPrimary.opacity(0.12), radius: 24, y: 12)
    }

    private var routeSection: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            routeRow(
                icon: "location.circle.fill",
                color: BIRGEColors.brandPrimary,
                title: store.originTitle,
                isPrimary: true
            )

            Rectangle()
                .fill(BIRGEColors.brandPrimary.opacity(0.35))
                .frame(width: 2, height: 18)
                .padding(.leading, 10)

            routeRow(
                icon: "mappin.circle.fill",
                color: BIRGEColors.danger,
                title: store.destinationTitle,
                isPrimary: false
            )
        }
    }

    private func routeRow(
        icon: String,
        color: Color,
        title: String,
        isPrimary: Bool
    ) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(isPrimary ? BIRGEFonts.bodyMedium : BIRGEFonts.body)
                .foregroundStyle(isPrimary ? BIRGEColors.textPrimary : BIRGEColors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var detailGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: BIRGELayout.s),
                GridItem(.flexible(), spacing: BIRGELayout.s)
            ],
            spacing: BIRGELayout.s
        ) {
            detailItem(icon: "clock.fill", label: "Отправление", value: store.departureTime)
            detailItem(icon: "timer", label: "В пути", value: store.durationText)
            detailItem(icon: "tengesign.circle.fill", label: "Стоимость", value: "\(store.fare)₸", isAccent: true)
            detailItem(icon: "person.3.fill", label: "Попутчики", value: store.seatsText)
        }
    }

    private func detailItem(
        icon: String,
        label: String,
        value: String,
        isAccent: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Label(label, systemImage: icon)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(value)
                .font(BIRGEFonts.title)
                .foregroundStyle(isAccent ? BIRGEColors.brandPrimary : BIRGEColors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var companionsSection: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text("ЕДУТ С ВАМИ")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textTertiary)

            HStack(spacing: BIRGELayout.xs) {
                HStack(spacing: -BIRGELayout.xxxs) {
                    ForEach(Array(store.companions.enumerated()), id: \.offset) { index, name in
                        companionAvatar(name: name, index: index)
                    }
                }

                Text(store.companions.joined(separator: ", "))
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
        }
    }

    private func companionAvatar(name: String, index: Int) -> some View {
        let colors = [
            BIRGEColors.brandPrimary,
            BIRGEColors.success,
            BIRGEColors.warning
        ]
        let color = colors[index % colors.count]

        return Text(String(name.prefix(1)))
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.14))
            .clipShape(Circle())
            .overlay(Circle().stroke(BIRGEColors.surfacePrimary, lineWidth: 2))
    }

    private var timerCard: some View {
        HStack(spacing: BIRGELayout.s) {
            Label("Подтвердите в течение", systemImage: "timer")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.warning)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: BIRGELayout.xs)

            Text(timerText)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(BIRGEColors.warning)
        }
        .padding(.horizontal, BIRGELayout.s)
        .padding(.vertical, BIRGELayout.xs)
        .liquidGlass(
            .card,
            tint: BIRGEColors.warning.opacity(0.10),
            isInteractive: true
        )
        .overlay(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .stroke(BIRGEColors.warning.opacity(0.24), lineWidth: 1)
        )
    }

    private var actionStack: some View {
        VStack(spacing: BIRGELayout.xs) {
            BIRGEPrimaryButton(
                title: "Подтвердить поездку · \(store.fare)₸",
                isLoading: store.isConfirming
            ) {
                send(.confirmTapped)
            }

            Button {
                send(.declineTapped)
            } label: {
                Label("Отклонить", systemImage: "xmark.circle")
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(BIRGEPressableButtonStyle())
            .disabled(store.isConfirming)
        }
    }

    private var timerText: String {
        let seconds = max(store.secondsRemaining, 0)
        return "0:\(String(format: "%02d", seconds))"
    }
}

#Preview {
    OfferFoundView(
        store: Store(
            initialState: OfferFoundFeature.State(
                rideId: "preview-ride",
                driverInfo: SearchingFeature.DriverInfo(
                    driverId: "driver-1",
                    driverName: "Асан Бекович",
                    driverRating: 4.9,
                    driverVehicle: "Chevrolet Nexia",
                    driverPlate: "777 ABA 02",
                    etaSeconds: 240
                )
            )
        ) {
            OfferFoundFeature()
        }
    )
}
