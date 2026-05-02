import ComposableArchitecture
import MapKit
import SwiftUI

@ViewAction(for: ActiveRideFeature.self)
struct ActiveRideView: View {
    @Bindable var store: StoreOf<ActiveRideFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.2220, longitude: 76.8512),
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            // LAYER 1 — Map
            Map(position: $position) {
                // Driver annotation
                Annotation(
                    "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: store.driverLat,
                        longitude: store.driverLng
                    )
                ) {
                    ZStack {
                        Circle()
                            .fill(BIRGEColors.brandPrimary)
                            .frame(width: BIRGELayout.minTapTarget, height: BIRGELayout.minTapTarget)
                            .shadow(color: BIRGEColors.brandPrimary.opacity(0.4), radius: 8, y: 4)
                        Image(systemName: "car.fill")
                            .font(BIRGEFonts.sectionTitle)
                            .foregroundStyle(BIRGEColors.textOnBrand)
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: store.driverLat)
                }

                // Passenger annotation
                Annotation(
                    "",
                    coordinate: CLLocationCoordinate2D(latitude: 43.2220, longitude: 76.8512)
                ) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                        Circle()
                            .fill(BIRGEColors.brandPrimary)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls { }
            .ignoresSafeArea()

            // LAYER 2 — Status pill
            statusPill
                .padding(.top, 60)
                .animation(reduceMotion ? nil : .spring(response: 0.5), value: store.status)
        }
        .safeAreaInset(edge: .bottom) {
            bottomSheet
                .animation(reduceMotion ? nil : .spring(response: 0.5), value: store.status)
        }
        .onAppear {
            send(.onAppear)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Status Pill

    @ViewBuilder
    private var statusPill: some View {
        let config = pillConfig(for: store.status)
        BIRGEStatusPill(label: "\(config.emoji) \(config.text)", color: config.color)
            .lineLimit(2)
            .frame(maxWidth: 200)
            .shadow(color: config.color.opacity(0.3), radius: 8, y: 4)
    }

    private func pillConfig(for status: RideStatus) -> (emoji: String, text: String, color: Color) {
        switch status {
        case .driverArriving:
            return ("🕐", "Водитель едет · \(store.etaMinutes) мин", BIRGEColors.brandPrimary)
        case .passengerWait:
            return ("🚗", "Водитель ждёт вас", BIRGEColors.warning)
        case .inProgress:
            return ("🟢", "Вы едете · \(store.etaMinutes) мин", BIRGEColors.success)
        default:
            return ("", "", BIRGEColors.textTertiary)
        }
    }

    // MARK: - Bottom Sheet

    @ViewBuilder
    private var bottomSheet: some View {
        VStack(spacing: 0) {
            BIRGESheetHandle()
                .padding(.top, BIRGELayout.xxs)
                .padding(.bottom, BIRGELayout.xs)

            switch store.status {
            case .driverArriving, .passengerWait:
                driverArrivingSheet
            case .inProgress:
                inProgressSheet
            default:
                EmptyView()
            }
        }
        .background(
            BIRGEColors.background
                .clipShape(
                    .rect(
                        topLeadingRadius: BIRGELayout.radiusL,
                        topTrailingRadius: BIRGELayout.radiusL
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        )
    }

    // MARK: - Driver Arriving Sheet

    @ViewBuilder
    private var driverArrivingSheet: some View {
        VStack(spacing: 0) {
            // Driver info row
            HStack(alignment: .top, spacing: BIRGELayout.xs) {
                // Avatar
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
                    Text("👨‍💼")
                        .font(BIRGEFonts.title)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.driver.name)
                        .font(.headline)

                    HStack(spacing: BIRGELayout.xxxs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.2f", store.driver.rating))
                            .font(.caption)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(store.driver.car)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(store.driver.plate)
                        .font(BIRGEFonts.captionBold)
                        .padding(.horizontal, BIRGELayout.xxs)
                        .padding(.vertical, BIRGELayout.xxxs)
                        .background(Color(.systemGray6))
                        .cornerRadius(BIRGELayout.radiusXS)
                }

                Spacer()

                // Call button
                Button {
                    send(.callDriverTapped)
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .font(BIRGEFonts.sectionTitle)
                        .frame(width: BIRGELayout.minTapTarget, height: BIRGELayout.minTapTarget)
                        .background(BIRGEColors.brandPrimary)
                        .clipShape(Circle())
                        .shadow(color: BIRGEColors.brandPrimary.opacity(0.3), radius: 6, y: 3)
                }
                .accessibilityLabel("Позвонить водителю")
            }
            .padding(BIRGELayout.m)

            Divider()

            // ETA row
            HStack(spacing: BIRGELayout.xxs) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(BIRGEColors.brandPrimary)
                    .font(BIRGEFonts.sectionTitle)

                if store.status == .passengerWait {
                    Text("Водитель ждёт вас у подъезда")
                        .font(.subheadline)
                } else {
                    Text("Вас заберут через ~\(store.etaMinutes) мин")
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.vertical, BIRGELayout.xs)

            // Cancel button
            Button {
                send(.cancelTapped)
            } label: {
                Text("Отменить поездку")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, BIRGELayout.m)
        }
    }

    // MARK: - In Progress Sheet

    @ViewBuilder
    private var inProgressSheet: some View {
        VStack(spacing: BIRGELayout.s) {
            HStack(alignment: .top, spacing: BIRGELayout.xs) {
                // Avatar
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
                    Text("👨‍💼")
                        .font(BIRGEFonts.title)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.driver.name)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.2f", store.driver.rating))
                            .font(.caption)
                    }
                }

                Spacer()

                // Fare badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("1 850₸")
                        .font(.title3)
                        .bold()
                        .foregroundColor(BIRGEColors.brandPrimary)
                    Text("Стоимость")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: BIRGELayout.xxs) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(BIRGEColors.brandPrimary)
                    .font(BIRGEFonts.sectionTitle)
                Text("Есентай Парк · ~\(store.etaMinutes) мин")
                    .font(.subheadline)
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
