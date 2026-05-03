import ComposableArchitecture
import MapKit
import SwiftUI

// MARK: - HomeView

@ViewAction(for: HomeFeature.self)
struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.2220, longitude: 76.8512),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            // LAYER 0 ── Full-screen Map
            mapLayer

            // LAYER 1 ── Right floating buttons
            HStack {
                Spacer()
                rightButtons
                    .padding(.trailing, BIRGELayout.s)
            }
            .frame(maxHeight: .infinity, alignment: .center)

            // LAYER 2 ── Search bar + AI pill
            topOverlays
        }
        .safeAreaInset(edge: .bottom) {
            bottomSheet
        }
        .task {
            send(.onAppear)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Map Layer

    private var mapLayer: some View {
        Map(position: $position) {
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls { }
        .ignoresSafeArea()
    }

    // MARK: - Top Overlays

    private var topOverlays: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
            // Search bar
            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .font(BIRGEFonts.body)
                Text("Куда едем?")
                    .font(BIRGEFonts.body)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, BIRGELayout.s)
            .frame(height: BIRGELayout.mapSearchBarHeight)
            .liquidGlass(.card)
            .padding(.horizontal, BIRGELayout.s)
            .padding(.top, BIRGELayout.mapSearchBarTop)
            .onTapGesture { send(.searchBarTapped) }

            // AI Pill
            Button {
                send(.aiExplanationTapped)
            } label: {
                BIRGEAIPill("AI нашёл \(store.aiMatchCount) коридора рядом")
            }
            .buttonStyle(.plain)
            .padding(.leading, BIRGELayout.s)
            .accessibilityLabel("Как AI подбирает коридоры")

            if let corridorError = store.corridorError {
                BIRGEToast(message: corridorError, style: .warning)
                    .padding(.horizontal, BIRGELayout.s)
            }
        }
    }

    // MARK: - Right Floating Buttons

    private var rightButtons: some View {
        VStack(spacing: BIRGELayout.xs) {
            // Profile
            Button { send(.profileButtonTapped) } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 46, height: 46)
                    .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.08))
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
            }
            .accessibilityLabel("Профиль")

            // My location
            Button { } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 46, height: 46)
                    .liquidGlass(.card)
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
            }
            .accessibilityLabel("Моё местоположение")
        }
    }

    // MARK: - Bottom Sheet

    private var bottomSheet: some View {
        BIRGEGlassSheet {
            VStack(spacing: 0) {
                // ── Section header
                HStack {
                    Text("Подобрано для вас")
                        .font(BIRGEFonts.sectionTitle)
                    Spacer()
                    Button {
                        send(.showAllCorridorsTapped)
                    } label: {
                        Text("Все →")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.brandPrimary)
                    }
                    .birgeTapTarget()
                }
                .padding(.horizontal, BIRGELayout.m)
                .padding(.bottom, BIRGELayout.xs)

                // ── Horizontal corridor scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BIRGELayout.xs) {
                        if store.isLoadingCorridors {
                            ProgressView()
                                .tint(BIRGEColors.brandPrimary)
                                .frame(width: 220, height: 132)
                                .birgeGlassCard()
                        }

                        ForEach(store.corridors) { corridor in
                            corridorCard(corridor)
                        }
                    }
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.bottom, BIRGELayout.xs)
                }

                Divider()
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.vertical, BIRGELayout.xs)

                // ── Quick Taxi
                quickTaxiCard
                    .padding(.horizontal, BIRGELayout.m)

                // ── Tab Bar
                tabBar
                    .padding(.top, BIRGELayout.xs)
            }
            .padding(.top, BIRGELayout.xxs)
        }
    }

    // MARK: - Corridor Card

    private func corridorCard(_ corridor: CorridorOption) -> some View {
        Button { send(.corridorTapped(corridor)) } label: {
            VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                BIRGEMatchBadge(corridor.matchPercent)

                Text(corridor.name)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(1)

                Text(corridor.departure)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)

                Divider()

                HStack(spacing: BIRGELayout.xxs) {
                    Label("\(corridor.seatsLeft)/\(corridor.seatsTotal)", systemImage: "person.2.fill")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                    Text("·")
                        .foregroundStyle(BIRGEColors.textTertiary)
                    Text("\(corridor.price)₸")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textPrimary)
                }

                // Passenger initials stack
                HStack(spacing: -BIRGELayout.xxs + 2) {
                    ForEach(corridor.passengerInitials.prefix(3), id: \.self) { initial in
                        Text(initial)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(BIRGEColors.brandPrimary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
            }
            .padding(BIRGELayout.s)
            .frame(width: 220, alignment: .leading)
            .birgeGlassCard()
        }
        .buttonStyle(BIRGEPressableButtonStyle())
    }

    // MARK: - Quick Taxi

    private var quickTaxiCard: some View {
        Button { send(.callTaxiTapped) } label: {
            HStack(spacing: BIRGELayout.s) {
                ZStack {
                    Circle()
                        .fill(BIRGEColors.brandPrimary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "car.fill")
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                }
                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text("Вызвать такси")
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text("Стандарт · ~4 мин · от 900₸")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textTertiary)
            }
            .padding(BIRGELayout.s)
            .birgeGlassCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack {
            tabItem(symbol: "map.fill", label: "Главная", isActive: true) { }
            tabItem(symbol: "car.fill", label: "Поездки", isActive: false) {
                send(.rideHistoryTapped)
            }
            tabItem(symbol: "creditcard.fill", label: "Подписка", isActive: false) {
                send(.subscriptionTapped)
            }
            tabItem(symbol: "person.fill", label: "Профиль", isActive: false) {
                send(.profileButtonTapped)
            }
        }
        .padding(.vertical, BIRGELayout.xs)
        .padding(.bottom, BIRGELayout.xxs)
    }

    private func tabItem(
        symbol: String,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(isActive ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isActive ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
