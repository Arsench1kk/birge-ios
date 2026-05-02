//
//  DriverAppView.swift
//  BIRGEDrive
//

import ComposableArchitecture
import SwiftUI

struct DriverAppView: View {
    @Bindable var store: StoreOf<DriverAppFeature>

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
            Color(.systemGroupedBackground)
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
        .animation(.spring(duration: 0.45), value: store.currentOffer != nil)
        .animation(.spring(duration: 0.45), value: store.activeRide != nil)
        .animation(.easeInOut(duration: 0.3), value: store.isOnline)
        .navigationBarHidden(true)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("BIRGE Driver")
                .font(.system(size: 22, weight: .bold))

            Spacer()

            // Earnings button
            Button {
                store.send(.earningsTapped)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 14))
                    Text("\(store.earnings.todayTenge)₸")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.green)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
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
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.green.opacity(0.08))
                    .frame(width: 110, height: 110)

                Image(systemName: "car.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.green)
            }

            VStack(spacing: 8) {
                Text("Вы офлайн")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Нажмите, чтобы начать принимать заказы")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                store.send(.toggleOnline)
            } label: {
                Text("Начать работу")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color(red: 0.1, green: 0.7, blue: 0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(18)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Online Waiting

    private var onlineWaiting: some View {
        VStack(spacing: 24) {
            ZStack {
                // Pulsing rings
                PulseRing(delay: 0.0, color: .green)
                PulseRing(delay: 0.5, color: .green)
                PulseRing(delay: 1.0, color: .green)

                Circle()
                    .fill(Color.green)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    )
            }
            .frame(width: 160, height: 160)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Онлайн • Ожидание")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Text("Ищем подходящие заказы для вас...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Today's stats mini card
            HStack(spacing: 20) {
                miniStat(label: "Поездок", value: "\(store.earnings.todayRides)")
                Divider().frame(height: 30)
                miniStat(label: "Заработок", value: "\(store.earnings.todayTenge)₸")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Offer Card

    private func offerCard(_ offer: DriverAppFeature.RideOffer) -> some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Новый заказ")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(offer.passengerName)
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    Text("\(offer.fare)₸")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.green)
                }

                Divider()

                // Route
                VStack(spacing: 10) {
                    routeRow(
                        icon: "circle.fill",
                        color: .green,
                        label: "Забрать",
                        address: offer.pickup
                    )
                    routeRow(
                        icon: "mappin.circle.fill",
                        color: .red,
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
                HStack(spacing: 12) {
                    Button {
                        store.send(.declineOffer)
                    } label: {
                        Text("Отклонить")
                            .font(.headline)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }

                    Button {
                        store.send(.acceptOffer)
                    } label: {
                        Text("Принять")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.green)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 0)
    }

    private func routeRow(icon: String, color: Color, label: String, address: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(address)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
        }
    }

    private func metricBadge(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Active Ride Banner

    private func activeRideBanner(_ ride: DriverAppFeature.DriverActiveRide) -> some View {
        VStack(spacing: 14) {
            // Status bar
            HStack {
                Circle()
                    .fill(statusColor(for: ride.status))
                    .frame(width: 10, height: 10)
                Text(statusText(for: ride.status))
                    .font(.headline)
                Spacer()
            }

            // Destination
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.red)
                Text(ride.destination)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
            }

            // Action button
            Button {
                switch ride.status {
                case .pickingUp:
                    store.send(.arrivedAtPickup)
                case .passengerWait:
                    store.send(.startRide)
                case .inProgress:
                    store.send(.completeRide)
                }
            } label: {
                Text(actionText(for: ride.status))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(statusColor(for: ride.status))
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.systemBackground))
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
            return .orange
        case .inProgress:
            return .green
        }
    }

    // MARK: - End Shift Button

    private var endShiftButton: some View {
        Button {
            store.send(.toggleOnline)
        } label: {
            Text("Завершить смену")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Pulse Ring Animation

private struct PulseRing: View {
    let delay: Double
    let color: Color

    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0.8

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
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
