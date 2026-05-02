import ComposableArchitecture
import MapKit
import SwiftUI

@ViewAction(for: HomeFeature.self)
struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.2220, longitude: 76.8512),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map layer
            Map(position: $position) {
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: store.driverLat, longitude: store.driverLng)) {
                    ZStack {
                        Circle()
                            .fill(BIRGEColors.brandPrimary)
                            .frame(width: BIRGELayout.xl, height: BIRGELayout.xl)
                        Image(systemName: "car.fill")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.textOnBrand)
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls { }
            .ignoresSafeArea()
            
            // Top Overlay
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                    Text("Доброе утро 👋")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                    
                    Button {
                        send(.searchBarTapped)
                    } label: {
                        HStack {
                            Text("🔍  Куда едем?")
                                .font(BIRGEFonts.body)
                                .foregroundStyle(BIRGEColors.textSecondary)
                            Spacer()
                        }
                        .padding(BIRGELayout.s)
                        .background(BIRGEColors.background)
                        .cornerRadius(BIRGELayout.radiusM)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, BIRGELayout.s)
                .padding(.top, BIRGELayout.s)
                
                Spacer()
                
                // Top Right Floating Button
                Button {
                    send(.profileButtonTapped)
                } label: {
                    ZStack {
                        Circle()
                            .fill(BIRGEColors.brandPrimary)
                            .frame(width: BIRGELayout.minTapTarget, height: BIRGELayout.minTapTarget)
                        Image(systemName: "person.fill")
                            .foregroundStyle(BIRGEColors.textOnBrand)
                    }
                }
                .accessibilityLabel("Профиль")
                .padding(.trailing, BIRGELayout.s)
                .padding(.top, BIRGELayout.s)
            }
            
        }
        .safeAreaInset(edge: .bottom) {
            bottomSheet
        }
        .navigationBarHidden(true)
    }
    
    var bottomSheet: some View {
        VStack(spacing: 0) {
            BIRGESheetHandle()
                .padding(.top, BIRGELayout.xxs)
                .padding(.bottom, BIRGELayout.s)
            
            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                Text("Мои коридоры")
                    .font(BIRGEFonts.sectionTitle)
                
                if store.corridors.isEmpty {
                    VStack(spacing: BIRGELayout.xs) {
                        Image(systemName: "map.circle")
                            .font(BIRGEFonts.heroNumber)
                            .foregroundColor(BIRGEColors.textTertiary)
                        Text("Коридоры загружаются...")
                            .foregroundColor(BIRGEColors.textSecondary)
                            .font(BIRGEFonts.body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BIRGELayout.xxl)
                } else {
                    ForEach(store.corridors) { corridor in
                        Button {
                            send(.corridorTapped(corridor))
                        } label: {
                            HStack(spacing: BIRGELayout.xs) {
                                Rectangle()
                                    .fill(BIRGEColors.brandPrimary)
                                    .frame(width: 3, height: 40)
                                
                                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                                    Text(corridor.name)
                                        .font(BIRGEFonts.bodyMedium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(corridor.departure)
                                        .font(BIRGEFonts.caption)
                                        .foregroundStyle(BIRGEColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: BIRGELayout.xxxs) {
                                    Text("\(corridor.price)₸")
                                        .font(BIRGEFonts.bodyMedium)
                                        .foregroundStyle(BIRGEColors.brandPrimary)
                                    Text("\(corridor.seatsLeft) места")
                                        .font(BIRGEFonts.caption)
                                        .foregroundStyle(BIRGEColors.textSecondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(BIRGEColors.textSecondary)
                            }
                            .padding(.horizontal, BIRGELayout.xs)
                            .frame(height: 80)
                            .birgeCard()
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, BIRGELayout.xxs)
                
                Button {
                    send(.callTaxiTapped)
                } label: {
                    HStack(spacing: BIRGELayout.s) {
                        Image(systemName: "car.fill")
                            .foregroundStyle(BIRGEColors.brandPrimary)
                            .font(BIRGEFonts.sectionTitle)
                        
                        Text("Стандарт  ·  ~4 мин  ·  от 900₸")
                            .font(BIRGEFonts.body)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                    .padding(.vertical, BIRGELayout.xxs)
                }
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.bottom, BIRGELayout.xl)
        }
        .frame(maxHeight: 220)
        .background(
            BIRGEColors.background
                .clipShape(
                    .rect(
                        topLeadingRadius: BIRGELayout.radiusL,
                        topTrailingRadius: BIRGELayout.radiusL
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
        )
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
