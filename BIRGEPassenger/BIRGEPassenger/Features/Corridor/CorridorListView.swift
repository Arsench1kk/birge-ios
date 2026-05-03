import ComposableArchitecture
import SwiftUI

struct CorridorListView: View {
    @Bindable var store: StoreOf<CorridorListFeature>

    var body: some View {
        ZStack(alignment: .top) {
            BIRGEColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                filterBar
                    .padding(.top, BIRGELayout.xxs)

                BIRGEAIPill(store.aiSummary)
                    .padding(.top, BIRGELayout.xxs)
                    .padding(.horizontal, BIRGELayout.m)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: BIRGELayout.xs) {
                        ForEach(store.filteredCorridors) { corridor in
                            corridorCard(corridor)
                        }

                        footer
                    }
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.top, BIRGELayout.xs)
                    .padding(.bottom, BIRGELayout.xxl)
                }
            }
        }
        .navigationTitle("Коридоры")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BIRGELayout.xxs) {
                ForEach(CorridorListFeature.State.Filter.allCases, id: \.self) { filter in
                    filterPill(filter)
                }
            }
            .padding(.horizontal, BIRGELayout.m)
        }
    }

    private func filterPill(_ filter: CorridorListFeature.State.Filter) -> some View {
        let isActive = store.selectedFilter == filter

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                _ = store.send(.filterSelected(filter))
            }
        } label: {
            Text(filter.rawValue)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(isActive ? BIRGEColors.textOnBrand : BIRGEColors.brandPrimary)
                .padding(.horizontal, BIRGELayout.s)
                .padding(.vertical, BIRGELayout.xxs)
                .background(isActive ? BIRGEColors.brandPrimary : BIRGEColors.brandPrimary.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func corridorCard(_ corridor: CorridorOption) -> some View {
        Button {
            store.send(.corridorTapped(corridor))
        } label: {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                HStack {
                    BIRGEMatchBadge(corridor.matchPercent)
                    Spacer()
                    seatsBadge(corridor)
                }

                routeStack(corridor)

                HStack(spacing: BIRGELayout.s) {
                    Label(corridor.departure, systemImage: "clock.fill")
                    Label("\(corridor.seatsLeft)/\(corridor.seatsTotal)", systemImage: "person.2.fill")
                    Label("\(corridor.price)₸", systemImage: "tengesign.circle.fill")
                }
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)

                Divider()

                HStack {
                    passengerStack(corridor)

                    if corridor.seatsLeft > 0 {
                        Text("+\(corridor.seatsLeft) свободно")
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                }
            }
            .padding(BIRGELayout.m)
            .birgeGlassCard()
        }
        .buttonStyle(.plain)
    }

    private func routeStack(_ corridor: CorridorOption) -> some View {
        let parts = corridor.name.components(separatedBy: " → ")

        return VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            routePoint(parts.first ?? corridor.name, color: BIRGEColors.brandPrimary)

            Rectangle()
                .fill(BIRGEColors.brandPrimary.opacity(0.28))
                .frame(width: 1.5, height: 16)
                .padding(.leading, 3)

            routePoint(parts.last ?? corridor.name, color: BIRGEColors.danger)
        }
    }

    private func routePoint(_ title: String, color: Color) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.textPrimary)
        }
    }

    private func passengerStack(_ corridor: CorridorOption) -> some View {
        HStack(spacing: -6) {
            ForEach(corridor.passengerInitials.prefix(3), id: \.self) { initial in
                Text(initial)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(width: 30, height: 30)
                    .background(BIRGEColors.brandPrimary.opacity(0.85))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(BIRGEColors.background, lineWidth: 2))
            }
        }
    }

    private func seatsBadge(_ corridor: CorridorOption) -> some View {
        let hasSeats = corridor.seatsLeft > 0

        return Text(hasSeats ? "\(corridor.seatsLeft) место" : "Занято")
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(hasSeats ? BIRGEColors.success : BIRGEColors.textSecondary)
            .padding(.horizontal, BIRGELayout.xs)
            .padding(.vertical, BIRGELayout.xxxs)
            .background(hasSeats ? BIRGEColors.success.opacity(0.12) : BIRGEColors.surfacePrimary)
            .clipShape(Capsule())
    }

    private var footer: some View {
        VStack(spacing: BIRGELayout.xxs) {
            Text("Это все коридоры по вашим маршрутам")
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)

            Button("Добавить новый маршрут") {}
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.brandPrimary)
        }
        .padding(.vertical, BIRGELayout.m)
    }
}

#Preview {
    NavigationStack {
        CorridorListView(
            store: Store(initialState: CorridorListFeature.State()) {
                CorridorListFeature()
            }
        )
    }
}
