import ComposableArchitecture
import MapKit
import SwiftUI

// MARK: - ActiveRideView

@ViewAction(for: ActiveRideFeature.self)
struct ActiveRideView: View {
    @Bindable var store: StoreOf<ActiveRideFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBoardingCodePresented = false

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.2220, longitude: 76.8512),
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            // LAYER 0 — Map
            Map(position: $position) {
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: store.driverLat,
                    longitude: store.driverLng
                )) {
                    ZStack {
                        Circle()
                            .fill(BIRGEColors.brandPrimary)
                            .frame(width: 44, height: 44)
                            .shadow(color: BIRGEColors.brandPrimary.opacity(0.4), radius: 8, y: 4)
                        Image(systemName: "car.fill")
                            .font(BIRGEFonts.sectionTitle)
                            .foregroundStyle(BIRGEColors.textOnBrand)
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: store.driverLat)
                }
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: 43.2220, longitude: 76.8512)) {
                    ZStack {
                        Circle().fill(.white).frame(width: 20, height: 20)
                        Circle().fill(BIRGEColors.brandPrimary).frame(width: 16, height: 16)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls { }
            .ignoresSafeArea()

            // LAYER 1 — Status Pill
            statusPill
                .padding(.top, 60)
                .animation(reduceMotion ? nil : .spring(response: 0.5), value: store.status)
        }
        .safeAreaInset(edge: .bottom) {
            BIRGEGlassSheet {
                switch store.status {
                case .driverArriving, .passengerWait:
                    driverArrivingSheet
                case .inProgress:
                    inProgressSheet
                default:
                    EmptyView()
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.5), value: store.status)
        }
        .sheet(isPresented: $isBoardingCodePresented) {
            BoardingCodeView(code: "847 291") {
                isBoardingCodePresented = false
            }
        }
        .onAppear { send(.onAppear) }
        .navigationBarHidden(true)
    }

    // MARK: - Status Pill (SF Symbols — no emoji)

    @ViewBuilder
    private var statusPill: some View {
        let config = pillConfig(for: store.status)
        HStack(spacing: BIRGELayout.xxs) {
            Image(systemName: config.symbol)
                .font(BIRGEFonts.captionBold)
            Text(config.text)
                .font(BIRGEFonts.captionBold)
        }
        .foregroundStyle(BIRGEColors.textOnBrand)
        .padding(.horizontal, BIRGELayout.s)
        .padding(.vertical, BIRGELayout.xxs)
        .background(config.color)
        .clipShape(Capsule())
        .shadow(color: config.color.opacity(0.4), radius: 10, y: 4)
    }

    private func pillConfig(for status: RideStatus) -> (symbol: String, text: String, color: Color) {
        switch status {
        case .driverArriving:
            return ("car.fill", "Водитель едет · \(store.etaMinutes) мин", BIRGEColors.brandPrimary)
        case .passengerWait:
            return ("mappin.circle.fill", "Водитель ждёт вас", BIRGEColors.warning)
        case .inProgress:
            return ("arrow.triangle.turn.up.right.circle.fill", "В пути · \(store.etaMinutes) мин", BIRGEColors.success)
        default:
            return ("clock", "", BIRGEColors.textTertiary)
        }
    }

    // MARK: - Driver Arriving Sheet

    @ViewBuilder
    private var driverArrivingSheet: some View {
        VStack(spacing: 0) {
            // Driver info
            HStack(alignment: .center, spacing: BIRGELayout.s) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(BIRGEColors.brandPrimary.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(BIRGEColors.brandPrimary)
                }

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(store.driver.name)
                        .font(BIRGEFonts.sectionTitle)

                    HStack(spacing: BIRGELayout.xxxs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.2f", store.driver.rating))
                            .font(BIRGEFonts.caption)
                        Text("·").foregroundStyle(BIRGEColors.textTertiary)
                        Text(store.driver.car)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }

                    Text(store.driver.plate)
                        .font(BIRGEFonts.captionBold)
                        .padding(.horizontal, BIRGELayout.xxs)
                        .padding(.vertical, BIRGELayout.xxxs)
                        .background(BIRGEColors.brandPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusXS))
                }

                Spacer()

                HStack(spacing: BIRGELayout.xs) {
                    // Chat button
                    Button { } label: {
                        Image(systemName: "message.fill")
                            .font(BIRGEFonts.body)
                            .foregroundStyle(BIRGEColors.brandPrimary)
                            .frame(width: 44, height: 44)
                            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.08))
                    }
                    .accessibilityLabel("Написать водителю")

                    // Call button
                    Button { send(.callDriverTapped) } label: {
                        Image(systemName: "phone.fill")
                            .font(BIRGEFonts.body)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(BIRGEColors.brandPrimary)
                            .clipShape(Circle())
                            .shadow(color: BIRGEColors.brandPrimary.opacity(0.4), radius: 8, y: 4)
                    }
                    .accessibilityLabel("Позвонить водителю")
                }
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.vertical, BIRGELayout.s)

            Divider().padding(.horizontal, BIRGELayout.m)

            // ETA row
            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: store.status == .passengerWait
                      ? "mappin.circle.fill" : "clock.fill")
                    .foregroundStyle(BIRGEColors.brandPrimary)
                Text(store.status == .passengerWait
                     ? "Водитель ждёт вас"
                     : "Вас заберут через ~\(store.etaMinutes) мин")
                    .font(BIRGEFonts.body)
                Spacer()
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.vertical, BIRGELayout.xs)

            // Boarding code button (only when passengerWait)
            if store.status == .passengerWait {
                Button {
                    isBoardingCodePresented = true
                } label: {
                    Label("Посмотреть код посадки", systemImage: "qrcode")
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BIRGELayout.xs)
                        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.06))
                        .padding(.horizontal, BIRGELayout.m)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            // Cancel
            Button { send(.cancelTapped) } label: {
                Text("Отменить поездку")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .birgeTapTarget()
            .padding(.bottom, BIRGELayout.s)
        }
    }

    // MARK: - In Progress Sheet

    @ViewBuilder
    private var inProgressSheet: some View {
        VStack(spacing: BIRGELayout.s) {
            HStack(alignment: .center, spacing: BIRGELayout.s) {
                ZStack {
                    Circle()
                        .fill(BIRGEColors.brandPrimary.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(BIRGEColors.brandPrimary)
                }

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(store.driver.name)
                        .font(BIRGEFonts.sectionTitle)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.2f", store.driver.rating))
                            .font(BIRGEFonts.caption)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("1 850₸")
                        .font(BIRGEFonts.heroNumber)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                    Text("Стоимость")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
            }

            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(BIRGEColors.brandPrimary)
                Text("Есентай Парк · ~\(store.etaMinutes) мин")
                    .font(BIRGEFonts.body)
                Spacer()
            }
        }
        .padding(BIRGELayout.m)
    }
}

#Preview {
    ActiveRideView(
        store: Store(initialState: ActiveRideFeature.State()) {
            ActiveRideFeature()
        }
    )
}
