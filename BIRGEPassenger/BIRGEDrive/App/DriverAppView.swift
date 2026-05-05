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
            DriverMapBackgroundView(
                isOnline: store.isOnline,
                hasActiveRide: store.activeRide != nil
            )
                .ignoresSafeArea()

            VStack(spacing: 0) {
                DriverTopBarView(
                    driverName: store.driverName,
                    vehicleTitle: store.vehicleTitle,
                    isOnline: store.isOnline,
                    isLoadingDriverProfile: store.isLoadingDriverProfile,
                    todayTenge: store.earnings.todayTenge
                ) {
                    store.send(.earningsTapped)
                }
                Spacer()
                centerContent
                Spacer()
            }

            if let offer = store.currentOffer {
                DriverOfferAlertView(offer: offer)
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.top, 112)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if store.isOnline && store.activeRide == nil && store.currentOffer == nil {
                DriverOnlineControlSheet(
                    earnings: store.earnings,
                    isLoadingTodayCorridors: store.isLoadingTodayCorridors,
                    todayCorridorsError: store.todayCorridorsError,
                    todayCorridors: store.todayCorridors
                ) {
                    store.send(.toggleOnline)
                }
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let offer = store.currentOffer {
                DriverOfferSheet(
                    offer: offer,
                    secondsRemaining: offerSecondsRemaining,
                    reduceMotion: reduceMotion,
                    accept: { store.send(.acceptOffer) },
                    decline: { store.send(.declineOffer) }
                )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let ride = store.activeRide {
                activeRideSheet(ride)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let summary = store.completedRideSummary {
                completedRideSheet(summary)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: store.currentOffer != nil)
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: store.activeRide != nil)
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: store.completedRideSummary != nil)
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

    // MARK: - Center Content

    @ViewBuilder
    private var centerContent: some View {
        if let ride = store.activeRide {
            activeRouteStatus(ride)
        } else if !store.isOnline {
            DriverOfflineCenterView(driverProfileError: store.driverProfileError) {
                store.send(.toggleOnline)
            }
        } else {
            DriverOnlineWaitingView()
        }
    }

    // MARK: - Active Ride

    private func activeRouteStatus(_ ride: DriverAppFeature.DriverActiveRide) -> some View {
        VStack(spacing: BIRGELayout.xs) {
            navigationCue(ride)

            Label(statusText(for: ride.status), systemImage: statusIcon(for: ride.status))
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(statusColor(for: ride.status))
                .padding(.horizontal, BIRGELayout.s)
                .padding(.vertical, BIRGELayout.xs)
                .liquidGlass(.pill, tint: statusColor(for: ride.status).opacity(0.08))

            HStack(spacing: BIRGELayout.xs) {
                metricChip(icon: "clock.fill", value: ride.status == .pickingUp ? "\(ride.etaMinutes) мин" : "~\(ride.etaMinutes) мин")
                metricChip(icon: "ruler.fill", value: String(format: "%.1f км", ride.distanceKm))
            }
        }
        .padding(.top, 72)
    }

    private func activeRideSheet(_ ride: DriverAppFeature.DriverActiveRide) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: statusIcon(for: ride.status))
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(statusColor(for: ride.status)))

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(statusText(for: ride.status))
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(statusSubtitle(for: ride))
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "phone.fill")
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .frame(width: 42, height: 42)
                        .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.08), isInteractive: true)
                }
                .accessibilityLabel("Позвонить пассажиру")
            }

            routeProgress(for: ride.status)

            navigationPanel(ride)

            VStack(spacing: BIRGELayout.xxs) {
                DriverRouteRow(
                    icon: "location.circle.fill",
                    color: BIRGEColors.success,
                    label: ride.status == .pickingUp ? "Точка посадки" : "Посадка завершена",
                    address: ride.pickup
                )
                DriverRouteRow(
                    icon: "mappin.circle.fill",
                    color: BIRGEColors.danger,
                    label: "Назначение",
                    address: ride.destination
                )
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: statusColor(for: ride.status).opacity(0.04))

            if ride.status == .passengerWait {
                boardingCodesCard
            } else {
                passengersCard(inProgress: ride.status == .inProgress)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BIRGELayout.xs), count: 2), spacing: BIRGELayout.xs) {
                DriverMetricTile(icon: "clock", label: ride.status == .pickingUp ? "До посадки" : "Осталось", value: ride.status == .pickingUp ? "\(ride.etaMinutes) мин" : "~\(ride.etaMinutes) мин")
                DriverMetricTile(icon: "ruler", label: "Маршрут", value: String(format: "%.1f км", ride.distanceKm))
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

    private func navigationCue(_ ride: DriverAppFeature.DriverActiveRide) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: maneuverSymbol(for: ride.status))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(width: 52, height: 52)
                .background(Circle().fill(statusColor(for: ride.status)))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(nextManeuverDistance(for: ride.status))
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Text(nextManeuverText(for: ride))
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(BIRGELayout.s)
        .frame(maxWidth: 320)
        .liquidGlass(.card, tint: statusColor(for: ride.status).opacity(0.08), isInteractive: true)
    }

    private func navigationPanel(_ ride: DriverAppFeature.DriverActiveRide) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack {
                Label("Навигация активна", systemImage: "location.north.line.fill")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(statusColor(for: ride.status))
                Spacer()
                Text(routePhaseText(for: ride.status))
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            HStack(alignment: .top, spacing: BIRGELayout.xs) {
                Image(systemName: maneuverSymbol(for: ride.status))
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(statusColor(for: ride.status)))

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(nextManeuverText(for: ride))
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textPrimary)
                        .lineLimit(2)
                    Text(routeGuidanceDetail(for: ride))
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: BIRGELayout.xs) {
                guidanceChip(icon: "clock.fill", value: "\(ride.etaMinutes) мин")
                guidanceChip(icon: "speedometer", value: "42 км/ч")
                guidanceChip(icon: "shield.lefthalf.filled", value: "спокойно")
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: statusColor(for: ride.status).opacity(0.045), isInteractive: true)
    }

    private func passengersCard(inProgress: Bool) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack {
                Text(inProgress ? "ПАССАЖИРЫ В САЛОНЕ" : "ПАССАЖИРЫ")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Spacer()
                Text(inProgress ? "Полный" : "4 места")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.success)
                    .padding(.horizontal, BIRGELayout.xs)
                    .padding(.vertical, BIRGELayout.xxxs)
                    .background(Capsule().fill(BIRGEColors.success.opacity(0.12)))
            }

            HStack(spacing: -8) {
                ForEach(Array(["А", "М", "Д", "А"].enumerated()), id: \.offset) { _, initial in
                    Text(initial)
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textOnBrand)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(avatarColor(for: initial)))
                        .overlay(Circle().stroke(BIRGEColors.background.opacity(0.8), lineWidth: 2))
                }
                Spacer()
                Label("Рейтинг 4.9", systemImage: "star.fill")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.warning)
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }

    private var boardingCodesCard: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text("КОДЫ ПОСАДКИ")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)

            ForEach(["АС 142", "МК 809", "ДБ 317", "АМ 551"], id: \.self) { code in
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(BIRGEColors.success)
                    Text(code)
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Spacer()
                    Text("готов")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.04))
    }

    private func completedRideSheet(_ summary: DriverAppFeature.CompletedRideSummary) -> some View {
        VStack(spacing: BIRGELayout.s) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(BIRGEColors.success)

            VStack(spacing: BIRGELayout.xxxs) {
                Text("Поездка завершена")
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("Отличная работа")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            VStack(spacing: BIRGELayout.s) {
                Text("\(summary.fare)₸")
                    .font(BIRGEFonts.heroNumber)
                    .foregroundStyle(BIRGEColors.success)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BIRGELayout.xs), count: 3), spacing: BIRGELayout.xs) {
                    completionStat(value: "\(summary.durationMinutes) мин", label: "Время")
                    completionStat(value: String(format: "%.1f км", summary.distanceKm), label: "Дистанция")
                    completionStat(value: "\(summary.passengers) чел", label: "Пассажиры")
                }
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.04))

            Label("\(summary.todayTenge)₸ · \(summary.todayRides) поездок сегодня", systemImage: "chart.line.uptrend.xyaxis")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .padding(.horizontal, BIRGELayout.s)
                .padding(.vertical, BIRGELayout.xs)
                .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.08))

            VStack(spacing: BIRGELayout.xs) {
                BIRGEPrimaryButton(title: "Следующая поездка") {
                    store.send(.findNextRide)
                }

                BIRGESecondaryButton(title: "Готово") {
                    store.send(.dismissCompletedRide)
                }
            }
        }
        .padding(BIRGELayout.m)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.06), isInteractive: true)
    }

    private func routeProgress(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> some View {
        VStack(spacing: BIRGELayout.xxs) {
            HStack {
                Text(progressLabel(for: status))
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Spacer()
                Text(progressValue(for: status))
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(statusColor(for: status))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(BIRGEColors.surfaceElevated)
                    Capsule()
                        .fill(statusColor(for: status))
                        .frame(width: proxy.size.width * progressAmount(for: status))
                }
            }
            .frame(height: 8)
        }
    }

    private func completionStat(value: String, label: String) -> some View {
        VStack(spacing: BIRGELayout.xxxs) {
            Text(value)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(label)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
    }

    private func metricChip(icon: String, value: String) -> some View {
        HStack(spacing: BIRGELayout.xxxs) {
            Image(systemName: icon)
            Text(value)
        }
        .font(BIRGEFonts.captionBold)
        .foregroundStyle(BIRGEColors.textPrimary)
        .padding(.horizontal, BIRGELayout.xs)
        .padding(.vertical, BIRGELayout.xxs)
        .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.05))
    }

    private func guidanceChip(icon: String, value: String) -> some View {
        Label(value, systemImage: icon)
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(BIRGEColors.textPrimary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, BIRGELayout.xs)
            .padding(.vertical, BIRGELayout.xxs)
            .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.035))
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

    private func statusSubtitle(for ride: DriverAppFeature.DriverActiveRide) -> String {
        switch ride.status {
        case .pickingUp:
            return "Точка посадки · \(ride.etaMinutes) мин · 1.2 км"
        case .passengerWait:
            return "Проверьте коды посадки и начните маршрут"
        case .inProgress:
            return "\(ride.destination) · ~\(ride.etaMinutes) мин"
        }
    }

    private func nextManeuverText(for ride: DriverAppFeature.DriverActiveRide) -> String {
        switch ride.status {
        case .pickingUp:
            return "Поверните направо к точке посадки"
        case .passengerWait:
            return "Остановитесь у входа и проверьте посадку"
        case .inProgress:
            return "Держитесь правее к \(ride.destination)"
        }
    }

    private func nextManeuverDistance(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "через 450 м"
        case .passengerWait:
            return "через 80 м"
        case .inProgress:
            return "через 1.2 км"
        }
    }

    private func routeGuidanceDetail(for ride: DriverAppFeature.DriverActiveRide) -> String {
        switch ride.status {
        case .pickingUp:
            return "Финиш подачи: \(ride.pickup)"
        case .passengerWait:
            return "После посадки маршрут продолжится до \(ride.destination)"
        case .inProgress:
            return "Финальная точка: \(ride.destination)"
        }
    }

    private func routePhaseText(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "Подача"
        case .passengerWait:
            return "Посадка"
        case .inProgress:
            return "В пути"
        }
    }

    private func maneuverSymbol(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "arrow.turn.up.right"
        case .passengerWait:
            return "parkingsign.circle.fill"
        case .inProgress:
            return "arrow.up.forward.circle.fill"
        }
    }

    private func statusIcon(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "car.fill"
        case .passengerWait:
            return "mappin.circle.fill"
        case .inProgress:
            return "arrow.triangle.turn.up.right.circle.fill"
        }
    }

    private func progressLabel(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "Подача"
        case .passengerWait:
            return "Посадка"
        case .inProgress:
            return "Маршрут"
        }
    }

    private func progressValue(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "35%"
        case .passengerWait:
            return "60%"
        case .inProgress:
            return "72%"
        }
    }

    private func progressAmount(for status: DriverAppFeature.DriverActiveRide.RideStatus) -> CGFloat {
        switch status {
        case .pickingUp:
            return 0.35
        case .passengerWait:
            return 0.60
        case .inProgress:
            return 0.72
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

    private func avatarColor(for initial: String) -> Color {
        switch initial {
        case "М":
            return BIRGEColors.success
        case "Д":
            return BIRGEColors.warning
        default:
            return BIRGEColors.brandPrimary
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
