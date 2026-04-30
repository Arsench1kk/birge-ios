import ComposableArchitecture
import MapKit
import SwiftUI

@ViewAction(for: ActiveRideFeature.self)
struct ActiveRideView: View {
    @Bindable var store: StoreOf<ActiveRideFeature>

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
                            .fill(BIRGEColors.blue)
                            .frame(width: 44, height: 44)
                            .shadow(color: BIRGEColors.blue.opacity(0.4), radius: 8, y: 4)
                        Image(systemName: "car.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                    .animation(.linear(duration: 1), value: store.driverLat)
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
                            .fill(BIRGEColors.blue)
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
                .animation(.spring(response: 0.5), value: store.status)
        }
        .safeAreaInset(edge: .bottom) {
            bottomSheet
                .animation(.spring(response: 0.5), value: store.status)
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
        HStack(spacing: 6) {
            Text(config.emoji)
            Text(config.text)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .frame(height: 36)
        .background(
            Capsule()
                .fill(config.color)
                .shadow(color: config.color.opacity(0.3), radius: 8, y: 4)
        )
    }

    private func pillConfig(for status: RideStatus) -> (emoji: String, text: String, color: Color) {
        switch status {
        case .driverArriving:
            return ("🕐", "Водитель едет · \(store.etaMinutes) мин", BIRGEColors.blue)
        case .passengerWait:
            return ("🚗", "Водитель ждёт вас", .orange)
        case .inProgress:
            return ("🟢", "Вы едете · \(store.etaMinutes) мин", .green)
        default:
            return ("", "", .gray)
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
            case .driverArriving, .passengerWait:
                driverArrivingSheet
            case .inProgress:
                inProgressSheet
            default:
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

    // MARK: - Driver Arriving Sheet

    @ViewBuilder
    private var driverArrivingSheet: some View {
        VStack(spacing: 0) {
            // Driver info row
            HStack(alignment: .top, spacing: 14) {
                // Avatar
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.driver.name)
                        .font(.headline)

                    HStack(spacing: 4) {
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
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }

                Spacer()

                // Call button
                Button {
                    send(.callDriverTapped)
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                        .frame(width: 44, height: 44)
                        .background(BIRGEColors.blue)
                        .clipShape(Circle())
                        .shadow(color: BIRGEColors.blue.opacity(0.3), radius: 6, y: 3)
                }
            }
            .padding(20)

            Divider()

            // ETA row
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(BIRGEColors.blue)
                    .font(.system(size: 20))

                if store.status == .passengerWait {
                    Text("Водитель ждёт вас у подъезда")
                        .font(.subheadline)
                } else {
                    Text("Вас заберут через ~\(store.etaMinutes) мин")
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Cancel button
            Button {
                send(.cancelTapped)
            } label: {
                Text("Отменить поездку")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - In Progress Sheet

    @ViewBuilder
    private var inProgressSheet: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                // Avatar
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
                        .foregroundColor(BIRGEColors.blue)
                    Text("Стоимость")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(BIRGEColors.blue)
                    .font(.system(size: 20))
                Text("Есентай Парк · ~\(store.etaMinutes) мин")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding(20)
    }
}

#Preview {
    ActiveRideView(
        store: Store(initialState: ActiveRideFeature.State()) {
            ActiveRideFeature()
        }
    )
}
