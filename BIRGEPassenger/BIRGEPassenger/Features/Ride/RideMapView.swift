//
//  RideMapView.swift
//  BIRGEPassenger
//
//  Live ride map with driver tracking and status overlay.
//  IOS-016 — RideFeature State Machine
//
//  Architecture ref: iOS_Architecture.md Section 5
//
//  Uses the iOS 17 Map { } API (same as existing ActiveRideView).
//  Renders driver location, pickup annotation, status pill,
//  and state-specific bottom sheets.
//

import BIRGECore
import ComposableArchitecture
import MapKit
import SwiftUI

// MARK: - RideMapView

@ViewAction(for: RideFeature.self)
struct RideMapView: View {
    @Bindable var store: StoreOf<RideFeature>

    private enum Texts {
        static let loading = "Обновляем поездку"
        static let connectionLost = "Нет соединения — восстанавливаем..."
    }

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.2220, longitude: 76.8512),
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            // LAYER 1 — Map
            mapLayer

            // LAYER 2 — Status pill
            statusPill
                .padding(.top, 60)
                .animation(.spring(response: 0.5), value: store.status)

            if store.isConnectionLost {
                connectionLostBanner
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if store.isLoading {
                loadingIndicator
                    .padding(.top, 116)
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let error = store.error {
                    errorToast(error)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                bottomSheet
                    .animation(.spring(response: 0.5), value: store.status)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.isLoading)
        .animation(.easeInOut(duration: 0.2), value: store.error)
        .animation(.easeInOut(duration: 0.2), value: store.isConnectionLost)
        .onAppear {
            send(.onAppear)
        }
        .onChange(of: store.driverLocation) { _, newLocation in
            guard let coord = newLocation else { return }
            withAnimation(.easeInOut(duration: 1.0)) {
                position = .region(
                    MKCoordinateRegion(
                        center: coord.clCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    )
                )
            }
        }
        .navigationBarHidden(true)
    }

    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.85)
            Text(Texts.loading)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(BIRGEColors.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private var connectionLostBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 14, weight: .semibold))
            Text(Texts.connectionLost)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private func errorToast(_ message: String) -> some View {
        Button {
            send(.errorDismissed)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Map Layer

    @ViewBuilder
    private var mapLayer: some View {
        Map(position: $position) {
            // Driver annotation (live-updating)
            if let driverCoord = store.driverLocation {
                Annotation("", coordinate: driverCoord.clCoordinate) {
                    ZStack {
                        Circle()
                            .fill(BIRGEColors.blue)
                            .frame(width: 44, height: 44)
                            .shadow(color: BIRGEColors.blue.opacity(0.4), radius: 8, y: 4)
                        Image(systemName: "car.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                    .animation(.linear(duration: 1), value: driverCoord)
                }
            }

            // Passenger pickup annotation (static)
            if let pickup = store.pickupLocation {
                Annotation("", coordinate: pickup.clCoordinate) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        Circle()
                            .fill(BIRGEColors.blue)
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .mapStyle(.standard)
        .mapControls { }
        .ignoresSafeArea()
    }

    // MARK: - Status Pill

    @ViewBuilder
    private var statusPill: some View {
        let config = pillConfig(for: store.status)

        if !config.text.isEmpty {
            HStack(spacing: 8) {
                if config.showSpinner {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
                Text(config.emoji)
                Text(config.text)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 40)
            .background(
                Capsule()
                    .fill(config.color)
                    .shadow(color: config.color.opacity(0.3), radius: 8, y: 4)
            )
        }
    }

    private func pillConfig(
        for status: RideStatus
    ) -> (emoji: String, text: String, color: Color, showSpinner: Bool) {
        switch status {
        case .requested:
            return ("", "Ищем водителя...", BIRGEColors.blue, true)
        case .matched, .driverAccepted:
            return ("✅", "Водитель принял заказ", .green, false)
        case .driverArriving:
            let eta = store.etaSeconds.map { "\($0) сек" } ?? "..."
            return ("🕐", "Водитель едет · \(eta)", BIRGEColors.blue, false)
        case .passengerWait:
            let code = store.verificationCode ?? "----"
            return ("🚗", "Код: \(code)", .orange, false)
        case .inProgress:
            let eta = store.etaSeconds.map { "\($0) сек" } ?? "..."
            return ("🟢", "Вы едете · \(eta)", .green, false)
        case .completed:
            return ("", "", .clear, false)
        case .cancelled:
            return ("❌", "Поездка отменена", .red, false)
        }
    }

    // MARK: - Bottom Sheet

    @ViewBuilder
    private var bottomSheet: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)

            switch store.status {
            case .requested:
                searchingSheet
            case .matched, .driverAccepted:
                driverAcceptedSheet
            case .driverArriving:
                driverArrivingSheet
            case .passengerWait:
                passengerWaitSheet
            case .inProgress:
                inProgressSheet
            case .cancelled:
                cancelledSheet
            case .completed:
                EmptyView()
            }
        }
        .background(
            Color.white
                .clipShape(
                    .rect(
                        topLeadingRadius: 24,
                        topTrailingRadius: 24
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        )
    }

    // MARK: - Sheet: Searching

    @ViewBuilder
    private var searchingSheet: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Ищем ближайшего водителя")
                .font(.headline)

            Text("Обычно это занимает 1–3 минуты")
                .font(.subheadline)
                .foregroundStyle(BIRGEColors.textSecondary)

            cancelButton
        }
        .padding(20)
    }

    // MARK: - Sheet: Driver Accepted

    @ViewBuilder
    private var driverAcceptedSheet: some View {
        VStack(spacing: 16) {
            driverInfoRow

            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                Text("Водитель принял ваш заказ")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 20)

            cancelButton
        }
        .padding(.vertical, 12)
    }

    // MARK: - Sheet: Driver Arriving

    @ViewBuilder
    private var driverArrivingSheet: some View {
        VStack(spacing: 0) {
            driverInfoRow
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            Divider()

            // ETA row
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(BIRGEColors.blue)
                    .font(.system(size: 20))

                if let eta = store.etaSeconds {
                    let minutes = eta / 60
                    Text("Вас заберут через ~\(max(1, minutes)) мин")
                        .font(.subheadline)
                } else {
                    Text("Водитель уже едет к вам")
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            cancelButton
                .padding(.bottom, 16)
        }
    }

    // MARK: - Sheet: Passenger Wait

    @ViewBuilder
    private var passengerWaitSheet: some View {
        VStack(spacing: 16) {
            driverInfoRow
                .padding(.horizontal, 20)

            Divider()

            // Verification code
            VStack(spacing: 8) {
                Text("Назовите водителю код:")
                    .font(.subheadline)
                    .foregroundStyle(BIRGEColors.textSecondary)

                Text(store.verificationCode ?? "----")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(BIRGEColors.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(BIRGEColors.blue.opacity(0.08))
                    )
            }

            // Countdown
            if let remaining = store.waitCountdownSeconds {
                let minutes = remaining / 60
                let seconds = remaining % 60
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("Ожидание: \(minutes):\(String(format: "%02d", seconds))")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            cancelButton
        }
        .padding(.vertical, 12)
    }

    // MARK: - Sheet: In Progress

    @ViewBuilder
    private var inProgressSheet: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                driverAvatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.driverName ?? "Водитель")
                        .font(.headline)
                    if let rating = store.driverRating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.2f", rating))
                                .font(.caption)
                        }
                    }
                }

                Spacer()

                // ETA badge
                if let eta = store.etaSeconds {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("~\(eta / 60) мин")
                            .font(.title3)
                            .bold()
                            .foregroundColor(BIRGEColors.blue)
                        Text("до прибытия")
                            .font(.caption)
                            .foregroundColor(BIRGEColors.textSecondary)
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(BIRGEColors.blue)
                    .font(.system(size: 20))
                Text("Вы едете к пункту назначения")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding(20)
    }

    // MARK: - Sheet: Cancelled

    @ViewBuilder
    private var cancelledSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)

            Text("Поездка отменена")
                .font(.headline)

            if let reason = store.cancellationReason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                send(.onDisappear)
            } label: {
                Text("Назад")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(BIRGEColors.blue)
                    .cornerRadius(12)
            }
        }
        .padding(20)
    }

    // MARK: - Reusable Components

    @ViewBuilder
    private var driverInfoRow: some View {
        HStack(alignment: .top, spacing: 14) {
            driverAvatar

            VStack(alignment: .leading, spacing: 4) {
                Text(store.driverName ?? "Водитель")
                    .font(.headline)

                HStack(spacing: 4) {
                    if let rating = store.driverRating {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.2f", rating))
                            .font(.caption)
                    }
                    if let vehicle = store.driverVehicle {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(vehicle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let plate = store.driverPlate {
                    Text(plate)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var driverAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [BIRGEColors.blue, BIRGEColors.blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
            Text("👨‍💼")
                .font(.system(size: 24))
        }
    }

    @ViewBuilder
    private var cancelButton: some View {
        Button {
            send(.cancelRideTapped(reason: "Пассажир отменил"))
        } label: {
            Text("Отменить поездку")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    RideMapView(
        store: Store(
            initialState: RideFeature.State(
                rideId: "preview-ride",
                status: .driverArriving,
                driverLocation: Coordinate(latitude: 43.2180, longitude: 76.8450),
                etaSeconds: 240,
                driverName: "Азамат К.",
                driverRating: 4.92,
                driverVehicle: "Toyota Camry",
                driverPlate: "777 AAA 02",
                pickupLocation: Coordinate(latitude: 43.2220, longitude: 76.8512)
            )
        ) {
            RideFeature()
        }
    )
}
