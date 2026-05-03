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
            driverMapBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                centerContent
                Spacer()
            }

            if let offer = store.currentOffer {
                offerAlert(offer)
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.top, 112)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if store.isOnline && store.activeRide == nil && store.currentOffer == nil {
                onlineControlSheet
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let offer = store.currentOffer {
                offerCard(offer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

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

    // MARK: - Map Background

    private var driverMapBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BIRGEColors.brandPrimary.opacity(0.16),
                    Color(.systemBackground),
                    BIRGEColors.success.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 34) {
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(BIRGEColors.textTertiary.opacity(0.08))
                        .frame(height: 1)
                }
            }
            .rotationEffect(.degrees(-14))
            .scaleEffect(1.35)

            HStack(spacing: 44) {
                ForEach(0..<8, id: \.self) { _ in
                    Rectangle()
                        .fill(BIRGEColors.textTertiary.opacity(0.06))
                        .frame(width: 1)
                }
            }
            .rotationEffect(.degrees(18))
            .scaleEffect(1.5)

            RoundedRectangle(cornerRadius: 32)
                .stroke(BIRGEColors.brandPrimary.opacity(0.24), style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [34, 22]))
                .frame(width: 260, height: 420)
                .rotationEffect(.degrees(27))
                .offset(x: -30, y: 78)

            RoundedRectangle(cornerRadius: 28)
                .stroke(BIRGEColors.success.opacity(0.24), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [24, 18]))
                .frame(width: 210, height: 320)
                .rotationEffect(.degrees(-22))
                .offset(x: 96, y: -120)

            if store.isOnline && store.activeRide == nil {
                ZStack {
                    Circle()
                        .stroke(BIRGEColors.success.opacity(0.16), lineWidth: 24)
                        .frame(width: 280, height: 280)
                    Circle()
                        .fill(BIRGEColors.success.opacity(0.08))
                        .frame(width: 210, height: 210)
                    Image(systemName: "car.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(BIRGEColors.textOnBrand)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(BIRGEColors.brandPrimary))
                        .shadow(color: BIRGEColors.brandPrimary.opacity(0.28), radius: 14, y: 7)
                }
                .offset(y: -12)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: BIRGELayout.xs) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("BIRGE Driver")
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)

                HStack(spacing: BIRGELayout.xxs) {
                    Image(systemName: store.isOnline ? "dot.radiowaves.left.and.right" : "power")
                        .font(BIRGEFonts.captionBold)
                    Text(store.isOnline ? "Онлайн" : "Офлайн")
                        .font(BIRGEFonts.captionBold)
                }
                .foregroundStyle(store.isOnline ? BIRGEColors.success : BIRGEColors.textSecondary)
            }

            Spacer()

            Button {
                store.send(.earningsTapped)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(BIRGEFonts.captionBold)
                    Text("\(store.earnings.todayTenge)₸")
                        .font(BIRGEFonts.captionBold)
                }
                .foregroundStyle(BIRGEColors.success)
                .padding(.horizontal, BIRGELayout.xs)
                .padding(.vertical, BIRGELayout.xs)
                .liquidGlass(.pill, tint: BIRGEColors.success.opacity(0.08), isInteractive: true)
            }
            .accessibilityLabel("Заработок сегодня: \(store.earnings.todayTenge) тенге")
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.s)
        .padding(.bottom, BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))
        .padding(.horizontal, BIRGELayout.s)
        .padding(.top, BIRGELayout.xs)
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
                    .fill(BIRGEColors.brandPrimary.opacity(0.12))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.08))
                    .frame(width: 110, height: 110)

                Image(systemName: "car.fill")
                    .font(BIRGEFonts.heroNumber)
                    .foregroundStyle(BIRGEColors.brandPrimary)
            }

            VStack(spacing: BIRGELayout.xxs) {
                Text("Вы офлайн")
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textPrimary)

                Text("Нажмите, чтобы начать принимать заказы")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            BIRGEPrimaryButton(title: "Начать работу") {
                store.send(.toggleOnline)
            }
            .padding(.horizontal, BIRGELayout.xl)
        }
        .padding(BIRGELayout.xl)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.05), isInteractive: true)
        .padding(.horizontal, BIRGELayout.m)
    }

    // MARK: - Online Waiting

    private var onlineWaiting: some View {
        VStack(spacing: BIRGELayout.m) {
            ZStack {
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
                        Image(systemName: "location.north.line.fill")
                            .font(BIRGEFonts.title)
                            .foregroundStyle(BIRGEColors.textOnBrand)
                    )
                    .shadow(color: BIRGEColors.success.opacity(0.32), radius: 18, y: 8)
            }
            .frame(width: 160, height: 160)

            VStack(spacing: BIRGELayout.xxs) {
                HStack(spacing: BIRGELayout.xxs) {
                    Circle()
                        .fill(BIRGEColors.success)
                        .frame(width: 8, height: 8)
                    Text("Онлайн • Ожидание")
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.textPrimary)
                }
                Text("Сканируем ближайшие коридоры")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.vertical, BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.05))
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(label)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
    }

    private var onlineControlSheet: some View {
        VStack(spacing: BIRGELayout.s) {
            HStack(spacing: BIRGELayout.s) {
                miniStat(label: "Поездок", value: "\(store.earnings.todayRides)")
                Divider().frame(height: 32)
                miniStat(label: "Сегодня", value: "\(store.earnings.todayTenge)₸")
                Divider().frame(height: 32)
                miniStat(label: "Неделя", value: "\(store.earnings.weekTenge)₸")
            }
            .padding(.horizontal, BIRGELayout.s)
            .padding(.vertical, BIRGELayout.xs)
            .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.04))

            VStack(spacing: BIRGELayout.xs) {
                Label("Алматы • активная зона", systemImage: "scope")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.success)
                    .lineLimit(1)

                endShiftButton
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.05), isInteractive: true)
    }

    private func offerAlert(_ offer: DriverAppFeature.RideOffer) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "bell.badge.fill")
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(width: 42, height: 42)
                .background(Circle().fill(BIRGEColors.success))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Новый заказ")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("\(offer.etaMinutes) мин до подачи • \(offer.fare)₸")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textTertiary)
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.07), isInteractive: true)
        .shadow(color: BIRGEColors.success.opacity(0.14), radius: 18, y: 8)
    }

    // MARK: - Offer Card

    private func offerCard(_ offer: DriverAppFeature.RideOffer) -> some View {
        BIRGEGlassSheet {
            BIRGESheetHandle()

            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                HStack(alignment: .top, spacing: BIRGELayout.s) {
                    countdownRing

                    VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                        HStack(spacing: BIRGELayout.xxs) {
                            Image(systemName: "sparkles")
                                .font(BIRGEFonts.captionBold)
                            Text("98% совпадение")
                                .font(BIRGEFonts.captionBold)
                        }
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .padding(.horizontal, BIRGELayout.xs)
                        .padding(.vertical, BIRGELayout.xxs)
                        .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.08))

                        Text(offer.passengerName)
                            .font(BIRGEFonts.sectionTitle)
                            .foregroundStyle(BIRGEColors.textPrimary)
                        Text("Комфортный маршрут рядом с вашей зоной")
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: BIRGELayout.xxxs) {
                        Text("\(offer.fare)₸")
                            .font(BIRGEFonts.heroNumber)
                            .foregroundStyle(BIRGEColors.success)
                        Text("за поездку")
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                }

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
                .padding(BIRGELayout.s)
                .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.035))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BIRGELayout.xs), count: 2), spacing: BIRGELayout.xs) {
                    metricTile(icon: "ruler", label: "Дистанция", value: "\(String(format: "%.1f", offer.distanceKm)) км")
                    metricTile(icon: "clock", label: "До подачи", value: "\(offer.etaMinutes) мин")
                    metricTile(icon: "person.2.fill", label: "Пассажиры", value: "1 место")
                    metricTile(icon: "bolt.car.fill", label: "Приоритет", value: "Высокий")
                }

                HStack(spacing: BIRGELayout.xs) {
                    passengerAvatar(name: offer.passengerName)
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text("Пассажир подтвержден")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.textPrimary)
                        Text("Рейтинг 4.9 • оплата в приложении")
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                    Spacer()
                }
                .padding(BIRGELayout.xs)
                .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.04))

                VStack(spacing: BIRGELayout.xs) {
                    BIRGEPrimaryButton(title: "Принять") {
                        store.send(.acceptOffer)
                    }

                    BIRGESecondaryButton(title: "Отклонить") {
                        store.send(.declineOffer)
                    }
                }
            }
        }
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
                    .foregroundStyle(BIRGEColors.textSecondary)
                Text(address)
                    .font(label == "Назначение" ? BIRGEFonts.bodyMedium : BIRGEFonts.body)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(2)
            }
        }
    }

    private func metricTile(icon: String, label: String, value: String) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: icon)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(BIRGEColors.brandPrimary.opacity(0.1)))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(value)
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(label)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }

    private func passengerAvatar(name: String) -> some View {
        Text(String(name.prefix(1)))
            .font(BIRGEFonts.bodyMedium)
            .foregroundStyle(BIRGEColors.textOnBrand)
            .frame(width: 42, height: 42)
            .background(Circle().fill(BIRGEColors.brandPrimary))
            .overlay(Circle().stroke(BIRGEColors.background.opacity(0.72), lineWidth: 2))
    }

    // MARK: - Active Ride Banner

    private func activeRideBanner(_ ride: DriverAppFeature.DriverActiveRide) -> some View {
        VStack(spacing: BIRGELayout.xs) {
            HStack {
                Circle()
                    .fill(statusColor(for: ride.status))
                    .frame(width: 10, height: 10)
                Text(statusText(for: ride.status))
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Spacer()
            }

            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(BIRGEColors.danger)
                Text(ride.destination)
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .lineLimit(2)
                Spacer()
            }

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
        .liquidGlass(.card, tint: statusColor(for: ride.status).opacity(0.06), isInteractive: true)
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
