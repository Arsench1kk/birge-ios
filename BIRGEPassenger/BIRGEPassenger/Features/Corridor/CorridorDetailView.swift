import ComposableArchitecture
import MapKit
import SwiftUI

struct CorridorDetailView: View {
    @Bindable var store: StoreOf<CorridorDetailFeature>
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.2220, longitude: 76.8512),
            span: MKCoordinateSpan(latitudeDelta: 0.055, longitudeDelta: 0.055)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 260)

                BIRGEGlassSheet {
                    content
                }
            }
        }
        .background(BIRGEColors.background)
        .navigationTitle("Маршрут")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var mapLayer: some View {
        Map(position: $position) {
            Annotation("Начало", coordinate: CLLocationCoordinate2D(latitude: 43.2380, longitude: 76.8890)) {
                mapPin("location.fill", color: BIRGEColors.brandPrimary)
            }
            Annotation("Финиш", coordinate: CLLocationCoordinate2D(latitude: 43.2190, longitude: 76.9270)) {
                mapPin("mappin.circle.fill", color: BIRGEColors.danger)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls { }
        .frame(height: 320)
        .ignoresSafeArea(edges: .top)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            HStack {
                BIRGEMatchBadge(store.corridor.matchPercent)
                Spacer()
                seatsBadge
            }

            Text(store.corridor.name)
                .font(BIRGEFonts.title)
                .foregroundStyle(BIRGEColors.textPrimary)

            Label(store.corridor.departure, systemImage: "clock.fill")
                .font(BIRGEFonts.body)
                .foregroundStyle(BIRGEColors.textSecondary)

            aiExplanationCard

            Divider()

            HStack(spacing: BIRGELayout.xl) {
                statItem(value: "\(store.corridor.price)₸", label: "Стоимость", symbol: "tengesign.circle.fill")
                statItem(value: "\(store.corridor.seatsLeft)/\(store.corridor.seatsTotal)", label: "Мест", symbol: "person.2.fill")
                statItem(value: "~35 мин", label: "В пути", symbol: "timer")
            }

            Divider()

            Text("Участники")
                .font(BIRGEFonts.sectionTitle)

            passengerRow

            BIRGEPrimaryButton(
                title: store.isJoining ? "Присоединяемся..." : "Присоединиться · \(store.corridor.price)₸",
                isLoading: store.isJoining
            ) {
                store.send(.joinTapped)
            }
            .disabled(store.isJoining || store.corridor.seatsLeft == 0)
            .padding(.top, BIRGELayout.xxs)
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.bottom, BIRGELayout.m)
    }

    private var aiExplanationCard: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "brain.head.profile")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 40, height: 40)
                .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.08))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Как AI создал этот коридор")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("847 похожих маршрутов · радиус 500 м · ±15 мин")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))
    }

    private func statItem(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: BIRGELayout.xxxs) {
            Image(systemName: symbol)
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.brandPrimary)
            Text(value)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(label)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var passengerRow: some View {
        HStack(spacing: BIRGELayout.xs) {
            ForEach(store.corridor.passengerInitials, id: \.self) { initial in
                VStack(spacing: BIRGELayout.xxxs) {
                    Text(initial)
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textOnBrand)
                        .frame(width: 44, height: 44)
                        .background(BIRGEColors.brandPrimary)
                        .clipShape(Circle())
                    Text("Пассажир")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
            }

            if store.corridor.seatsLeft > 0 {
                VStack(spacing: BIRGELayout.xxxs) {
                    Image(systemName: "plus")
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .frame(width: 44, height: 44)
                        .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.08))
                    Text("Вы")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
            }
        }
    }

    private var seatsBadge: some View {
        let hasSeats = store.corridor.seatsLeft > 0

        return Text(hasSeats ? "Места есть" : "Занято")
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(hasSeats ? BIRGEColors.success : BIRGEColors.textSecondary)
            .padding(.horizontal, BIRGELayout.xs)
            .padding(.vertical, BIRGELayout.xxxs)
            .background(hasSeats ? BIRGEColors.success.opacity(0.12) : BIRGEColors.surfacePrimary)
            .clipShape(Capsule())
    }

    private func mapPin(_ symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(BIRGEFonts.bodyMedium)
            .foregroundStyle(BIRGEColors.textOnBrand)
            .frame(width: 36, height: 36)
            .background(color)
            .clipShape(Circle())
            .shadow(color: color.opacity(0.35), radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        CorridorDetailView(
            store: Store(initialState: CorridorDetailFeature.State(corridor: CorridorOption.mock[0])) {
                CorridorDetailFeature()
            }
        )
    }
}
