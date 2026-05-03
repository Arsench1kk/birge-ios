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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                .animation(reduceMotion ? nil : .spring(response: 0.5), value: store.status)

            if store.isConnectionLost {
                connectionLostBanner
                    .padding(.top, 8)
                    .padding(.horizontal, BIRGELayout.s)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if store.isLoading {
                loadingIndicator
                    .padding(.top, 116)
                    .padding(.trailing, BIRGELayout.s)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let error = store.error {
                    errorToast(error)
                        .padding(.horizontal, BIRGELayout.s)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                bottomSheet
                    .animation(reduceMotion ? nil : .spring(response: 0.5), value: store.status)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.isLoading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.error)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.isConnectionLost)
        .onAppear {
            send(.onAppear)
        }
        .onChange(of: store.driverLocation) { _, newLocation in
            guard let coord = newLocation else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
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
        HStack(spacing: BIRGELayout.xxs) {
            ProgressView()
                .scaleEffect(0.85)
            Text(Texts.loading)
                .font(BIRGEFonts.captionBold)
        }
        .foregroundStyle(BIRGEColors.textSecondary)
        .padding(.horizontal, BIRGELayout.xs)
        .frame(height: 38)
        .liquidGlass(.pill, isInteractive: true)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private var connectionLostBanner: some View {
        BIRGEToast(message: Texts.connectionLost, style: .warning)
            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private func errorToast(_ message: String) -> some View {
        Button {
            send(.errorDismissed)
        } label: {
            BIRGEToast(message: message, style: .error)
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
                            .fill(BIRGEColors.brandPrimary)
                            .frame(width: BIRGELayout.minTapTarget, height: BIRGELayout.minTapTarget)
                            .shadow(color: BIRGEColors.brandPrimary.opacity(0.4), radius: 8, y: 4)
                        Image(systemName: "car.fill")
                            .font(BIRGEFonts.sectionTitle)
                            .foregroundStyle(BIRGEColors.textOnBrand)
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: driverCoord)
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
                            .fill(BIRGEColors.brandPrimary)
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
                if !config.symbol.isEmpty {
                    Image(systemName: config.symbol)
                        .font(BIRGEFonts.captionBold)
                }
                Text(config.text)
                    .font(BIRGEFonts.captionBold)
                    .lineLimit(2)
            }
            .foregroundStyle(BIRGEColors.textOnBrand)
            .padding(.horizontal, BIRGELayout.m)
            .frame(height: 40)
            .frame(maxWidth: 200)
            .background(
                Capsule()
                    .fill(config.color)
                    .shadow(color: config.color.opacity(0.3), radius: 8, y: 4)
            )
        }
    }

    private func pillConfig(
        for status: RideStatus
    ) -> (symbol: String, text: String, color: Color, showSpinner: Bool) {
        switch status {
        case .requested:
            return ("", "Ищем водителя...", BIRGEColors.brandPrimary, true)
        case .matched, .driverAccepted:
            return ("checkmark.circle.fill", "Водитель принял заказ", BIRGEColors.success, false)
        case .driverArriving:
            let eta = store.etaSeconds.map { "\($0) сек" } ?? "..."
            return ("clock.fill", "Водитель едет · \(eta)", BIRGEColors.brandPrimary, false)
        case .passengerWait:
            let code = store.verificationCode ?? "----"
            return ("car.fill", "Код: \(code)", BIRGEColors.warning, false)
        case .inProgress:
            let eta = store.etaSeconds.map { "\($0) сек" } ?? "..."
            return ("arrow.triangle.turn.up.right.circle.fill", "Вы едете · \(eta)", BIRGEColors.success, false)
        case .completed:
            return ("", "", .clear, false)
        case .cancelled:
            return ("xmark.circle.fill", "Поездка отменена", BIRGEColors.danger, false)
        }
    }

    // MARK: - Bottom Sheet

    @ViewBuilder
    private var bottomSheet: some View {
        if store.status != .completed {
            BIRGEGlassSheet {
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
        }
    }

    // MARK: - Sheet: Searching

    @ViewBuilder
    private var searchingSheet: some View {
        VStack(spacing: BIRGELayout.s) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Ищем ближайшего водителя")
                .font(.headline)

            Text("Обычно это занимает 1–3 минуты")
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)

            cancelButton
        }
        .padding(BIRGELayout.m)
    }

    // MARK: - Sheet: Driver Accepted

    @ViewBuilder
    private var driverAcceptedSheet: some View {
        VStack(spacing: BIRGELayout.s) {
            driverInfoRow

            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(BIRGEColors.success)
                    .font(BIRGEFonts.sectionTitle)
                Text("Водитель принял ваш заказ")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, BIRGELayout.m)

            cancelButton
        }
        .padding(.vertical, BIRGELayout.xs)
    }

    // MARK: - Sheet: Driver Arriving

    @ViewBuilder
    private var driverArrivingSheet: some View {
        VStack(spacing: 0) {
            driverInfoRow
                .padding(.horizontal, BIRGELayout.m)
                .padding(.vertical, BIRGELayout.s)

            Divider()

            // ETA row
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(BIRGEColors.brandPrimary)
                    .font(BIRGEFonts.sectionTitle)

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
            .padding(.horizontal, BIRGELayout.m)
            .padding(.vertical, BIRGELayout.xs)

            cancelButton
                .padding(.bottom, BIRGELayout.s)
        }
    }

    // MARK: - Sheet: Passenger Wait

    @ViewBuilder
    private var passengerWaitSheet: some View {
        VStack(spacing: BIRGELayout.s) {
            driverInfoRow
                .padding(.horizontal, BIRGELayout.m)

            Divider()

            // Verification code
            VStack(spacing: 8) {
                Text("Назовите водителю код:")
                    .font(.subheadline)
                    .foregroundStyle(BIRGEColors.textSecondary)

                Text(store.verificationCode ?? "----")
                    .font(BIRGEFonts.verifyCode)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .padding(.horizontal, BIRGELayout.l)
                    .padding(.vertical, BIRGELayout.xs)
                    .background(
                        RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                            .fill(BIRGEColors.brandPrimary.opacity(0.08))
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Код посадки: \(store.verificationCode ?? "----")")
            }

            // Countdown
            if let remaining = store.waitCountdownSeconds {
                let minutes = remaining / 60
                let seconds = remaining % 60
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("Ожидание: \(minutes):\(String(format: "%02d", seconds))")
                        .font(BIRGEFonts.subtext)
                        .foregroundStyle(BIRGEColors.warning)
                }
            }

            cancelButton
        }
        .padding(.vertical, BIRGELayout.xs)
    }

    // MARK: - Sheet: In Progress

    @ViewBuilder
    private var inProgressSheet: some View {
        VStack(spacing: BIRGELayout.s) {
            HStack(alignment: .top, spacing: BIRGELayout.xs) {
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
                            .font(BIRGEFonts.sectionTitle)
                            .foregroundColor(BIRGEColors.brandPrimary)
                        Text("до прибытия")
                            .font(.caption)
                            .foregroundColor(BIRGEColors.textSecondary)
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(BIRGEColors.brandPrimary)
                    .font(BIRGEFonts.sectionTitle)
                Text("Вы едете к пункту назначения")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding(BIRGELayout.m)
    }

    // MARK: - Sheet: Cancelled

    @ViewBuilder
    private var cancelledSheet: some View {
        VStack(spacing: BIRGELayout.s) {
            Image(systemName: "xmark.circle.fill")
                .font(BIRGEFonts.heroNumber)
                .foregroundColor(BIRGEColors.danger)

            Text("Поездка отменена")
                .font(.headline)

            if let reason = store.cancellationReason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            BIRGEPrimaryButton(title: "На главную") {
                send(.backToHomeTapped)
            }
        }
        .padding(BIRGELayout.m)
    }

    // MARK: - Reusable Components

    @ViewBuilder
    private var driverInfoRow: some View {
        HStack(alignment: .top, spacing: BIRGELayout.xs) {
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
                        .font(BIRGEFonts.captionBold)
                        .padding(.horizontal, BIRGELayout.xxs)
                        .padding(.vertical, BIRGELayout.xxxs)
                        .background(Color(.systemGray6))
                        .cornerRadius(BIRGELayout.radiusXS)
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
                        colors: [BIRGEColors.brandPrimary, BIRGEColors.brandPrimary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
            Image(systemName: "person.fill")
                .font(BIRGEFonts.title)
                .foregroundStyle(BIRGEColors.textOnBrand)
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
