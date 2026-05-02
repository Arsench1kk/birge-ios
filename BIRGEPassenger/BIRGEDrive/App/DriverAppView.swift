//
//  DriverAppView.swift
//  BIRGEDrive
//

import ComposableArchitecture
import SwiftUI

struct DriverAppView: View {
    @Bindable var store: StoreOf<DriverAppFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offerSecondsRemaining = 15
    @State private var offerTimerTask: Task<Void, Never>?

    private enum Texts {
        static let pickingUpStatus = "Едем за пассажиром"
        static let passengerWaitStatus = "Ожидаем пассажира"
        static let inProgressStatus = "Поездка началась"
        static let arrivedAtPickup = "Прибыл к пассажиру"
        static let startRide = "Начать поездку"
        static let completeRide = "Завершить поездку"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            BIRGEColors.surfaceGrouped
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                centerContent
                Spacer()
            }

            // Bottom controls
            if store.isOnline && store.activeRide == nil {
                endShiftButton
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Offer card slides up from bottom
            if let offer = store.currentOffer {
                offerCard(offer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Active ride banner
            if let ride = store.activeRide {
                activeRideBanner(ride)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: store.currentOffer != nil)
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: store.activeRide != nil)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: store.isOnline)
        .onChange(of: store.currentOffer != nil) { _, hasOffer in
            if hasOffer {
                startOfferCountdown()
            } else {
                offerTimerTask?.cancel()
                offerSecondsRemaining = 15
            }
        }
        .onDisappear {
            offerTimerTask?.cancel()
        }
        .navigationBarHidden(true)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("BIRGE Driver")
                .font(BIRGEFonts.title)

            Spacer()

            // Earnings button
            Button {
                store.send(.earningsTapped)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "banknote.fill")
                        .font(BIRGEFonts.captionBold)
                    Text("\(store.earnings.todayTenge)₸")
                        .font(BIRGEFonts.captionBold)
                }
                .foregroundStyle(BIRGEColors.textOnBrand)
                .padding(.horizontal, BIRGELayout.xs)
                .padding(.vertical, BIRGELayout.xxs)
                .background(
                    Capsule().fill(BIRGEColors.success)
                )
            }
            .accessibilityLabel("Заработок сегодня: \(store.earnings.todayTenge) тенге")
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.s)
        .padding(.bottom, BIRGELayout.xs)
        .background(BIRGEColors.background)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Center Content

    @ViewBuilder
    private var centerContent: some View {
        if store.activeRide != nil {
            // Active ride dominates center — banner handles all
            Spacer()
        } else if !store.isOnline {
            offlineCenter
        } else {
            onlineWaiting
        }
    }

    // MARK: - Offline Center

    private var offlineCenter: some View {
        VStack(spacing: BIRGELayout.l) {
            ZStack {
                Circle()
                    .fill(BIRGEColors.success.opacity(0.12))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(BIRGEColors.success.opacity(0.08))
                    .frame(width: 110, height: 110)

                Image(systemName: "car.fill")
                    .font(BIRGEFonts.heroNumber)
                    .foregroundStyle(BIRGEColors.success)
            }

            VStack(spacing: BIRGELayout.xxs) {
                Text("Вы офлайн")
                    .font(BIRGEFonts.title)
                    .foregroundStyle(.primary)

                Text("Нажмите, чтобы начать принимать заказы")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            BIRGEPrimaryButton(title: "Начать работу") {
                store.send(.toggleOnline)
            }
            .padding(.horizontal, BIRGELayout.xl)
        }
    }

    // MARK: - Online Waiting

    private var onlineWaiting: some View {
        VStack(spacing: BIRGELayout.l) {
            ZStack {
                // Pulsing rings
                if reduceMotion {
                    ProgressView()
                        .tint(BIRGEColors.success)
                        .scaleEffect(1.3)
                } else {
                    PulseRing(delay: 0.0, color: BIRGEColors.success)
                    PulseRing(delay: 0.5, color: BIRGEColors.success)
                    PulseRing(delay: 1.0, color: BIRGEColors.success)
                }

                Circle()
                    .fill(BIRGEColors.success)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(BIRGEFonts.title)
                            .foregroundStyle(BIRGEColors.textOnBrand)
                    )
            }
            .frame(width: 160, height: 160)

            VStack(spacing: BIRGELayout.xxs) {
                HStack(spacing: BIRGELayout.xxs) {
                    Circle()
                        .fill(BIRGEColors.success)
                        .frame(width: 8, height: 8)
                    Text("Онлайн • Ожидание")
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(.primary)
                }
                Text("Ищем подходящие заказы для вас...")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(.secondary)
            }

            // Today's stats mini card
            HStack(spacing: BIRGELayout.m) {
                miniStat(label: "Поездок", value: "\(store.earnings.todayRides)")
                Divider().frame(height: 30)
                miniStat(label: "Заработок", value: "\(store.earnings.todayTenge)₸")
            }
            .padding(.horizontal, BIRGELayout.l)
            .padding(.vertical, BIRGELayout.xs)
            .birgeCard()
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(BIRGEFonts.bodyMedium)
            Text(label)
                .font(BIRGEFonts.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Offer Card

    private func offerCard(_ offer: DriverAppFeature.RideOffer) -> some View {
        VStack(spacing: 0) {
            // Handle bar
            BIRGESheetHandle()
                .padding(.top, BIRGELayout.xs)

            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                countdownRing
                    .frame(maxWidth: .infinity)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text("Новый заказ")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(offer.passengerName)
                            .font(BIRGEFonts.sectionTitle)
                    }
                    Spacer()
                    Text("\(offer.fare)₸")
                        .font(BIRGEFonts.heroNumber)
                        .foregroundStyle(BIRGEColors.success)
                }

                Divider()

                // Route
                VStack(spacing: BIRGELayout.xxs) {
                    routeRow(
                        icon: "circle.fill",
                        color: BIRGEColors.success,
                        label: "Забрать",
                        address: offer.pickup
                    )
                    routeRow(
                        icon: "mappin.circle.fill",
                        color: BIRGEColors.danger,
                        label: "Назначение",
                        address: offer.destination
                    )
                }

                Divider()

                // Metrics
                HStack {
                    metricBadge(icon: "ruler", label: "\(String(format: "%.1f", offer.distanceKm)) км")
                    Spacer()
                    metricBadge(icon: "clock", label: "\(offer.etaMinutes) мин")
                }

                // Action buttons
                VStack(spacing: BIRGELayout.xs) {
                    BIRGEPrimaryButton(title: "Принять") {
                        store.send(.acceptOffer)
                    }

                    BIRGESecondaryButton(title: "Отклонить") {
                        store.send(.declineOffer)
                    }
                }
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.vertical, BIRGELayout.s)
        }
        .background(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .fill(BIRGEColors.background)
                .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 0)
    }

    private func routeRow(icon: String, color: Color, label: String, address: String) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: icon)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(label)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(.secondary)
                Text(address)
                    .font(label == "Назначение" ? BIRGEFonts.bodyMedium : BIRGEFonts.body)
                    .lineLimit(2)
            }
        }
    }

    private func metricBadge(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(BIRGEFonts.caption)
                .foregroundStyle(.secondary)
            Text(label)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(BIRGELayout.radiusXS)
    }

    // MARK: - Active Ride Banner

    private func activeRideBanner(_ ride: DriverAppFeature.DriverActiveRide) -> some View {
        VStack(spacing: BIRGELayout.xs) {
            // Status bar
            HStack {
                Circle()
                    .fill(statusColor(for: ride.status))
                    .frame(width: 10, height: 10)
                Text(statusText(for: ride.status))
                    .font(BIRGEFonts.sectionTitle)
                Spacer()
            }

            // Destination
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.red)
                Text(ride.destination)
                    .font(BIRGEFonts.subtext)
                    .lineLimit(2)
                Spacer()
            }

            // Action button
            BIRGEPrimaryButton(title: actionText(for: ride.status)) {
                switch ride.status {
                case .pickingUp:
                    store.send(.arrivedAtPickup)
                case .passengerWait:
                    store.send(.startRide)
                case .inProgress:
                    store.send(.completeRide)
                }
            }
        }
        .padding(BIRGELayout.m)
        .background(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .fill(BIRGEColors.background)
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: -4)
        )
    }

    private func statusText(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> String {
        switch status {
        case .pickingUp:
            return Texts.pickingUpStatus
        case .passengerWait:
            return Texts.passengerWaitStatus
        case .inProgress:
            return Texts.inProgressStatus
        }
    }

    private func actionText(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> String {
        switch status {
        case .pickingUp:
            return Texts.arrivedAtPickup
        case .passengerWait:
            return Texts.startRide
        case .inProgress:
            return Texts.completeRide
        }
    }

    private func statusColor(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> Color {
        switch status {
        case .pickingUp, .passengerWait:
            return BIRGEColors.warning
        case .inProgress:
            return BIRGEColors.success
        }
    }

    // MARK: - End Shift Button

    private var endShiftButton: some View {
        BIRGESecondaryButton(title: "Завершить смену") {
            store.send(.toggleOnline)
        }
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(BIRGEColors.surfaceElevated, lineWidth: 7)
                .frame(width: 64, height: 64)
            Circle()
                .trim(from: 0, to: CGFloat(max(offerSecondsRemaining, 0)) / 15)
                .stroke(countdownColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 64, height: 64)
                .animation(reduceMotion ? nil : .linear(duration: 1), value: offerSecondsRemaining)
            Text("\(offerSecondsRemaining)")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(countdownColor)
        }
        .accessibilityLabel("Осталось \(offerSecondsRemaining) секунд")
    }

    private var countdownColor: Color {
        if offerSecondsRemaining <= 3 {
            return BIRGEColors.danger
        } else if offerSecondsRemaining <= 7 {
            return BIRGEColors.warning
        }
        return BIRGEColors.success
    }

    private func startOfferCountdown() {
        offerTimerTask?.cancel()
        offerSecondsRemaining = 15
        offerTimerTask = Task { @MainActor in
            while offerSecondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                offerSecondsRemaining -= 1
            }
        }
    }
}

// MARK: - Pulse Ring Animation

private struct PulseRing: View {
    let delay: Double
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0.8

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .scaleEffect(scale)
            .onAppear {
                let animation = Animation.easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                withAnimation(reduceMotion ? nil : animation) {
                    scale = 1.6
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DriverAppView(
            store: Store(initialState: DriverAppFeature.State()) {
                DriverAppFeature()
            }
        )
    }
}
