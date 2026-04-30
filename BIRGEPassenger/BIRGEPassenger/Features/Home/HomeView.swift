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
                            .fill(BIRGEColors.blue)
                            .frame(width: 32, height: 32)
                        Text("🚗")
                            .font(.system(size: 16))
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls { }
            .ignoresSafeArea()
            
            // Top Overlay
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Доброе утро 👋")
                        .font(.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                    
                    Button {
                        send(.searchBarTapped)
                    } label: {
                        HStack {
                            Text("🔍  Куда едем?")
                                .foregroundStyle(BIRGEColors.textSecondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Top Right Floating Button
                Button {
                    send(.profileButtonTapped)
                } label: {
                    ZStack {
                        Circle()
                            .fill(BIRGEColors.blue)
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white)
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
            
        }
        .safeAreaInset(edge: .bottom) {
            bottomSheet
        }
        .navigationBarHidden(true)
    }
    
    var bottomSheet: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Мои коридоры")
                    .font(.system(size: 17, weight: .bold))
                
                if store.corridors.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "map.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Коридоры загружаются...")
                            .foregroundColor(.gray)
                            .font(.system(size: 15))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(store.corridors) { corridor in
                        Button {
                            send(.corridorTapped(corridor))
                        } label: {
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(BIRGEColors.blue)
                                    .frame(width: 3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(corridor.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.primary)
                                    Text(corridor.departure)
                                        .font(.caption)
                                        .foregroundStyle(BIRGEColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(corridor.price)₸")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(BIRGEColors.blue)
                                    Text("\(corridor.seatsLeft) места")
                                        .font(.caption)
                                        .foregroundStyle(BIRGEColors.textSecondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(BIRGEColors.textSecondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.trailing, 12)
                            .background(BIRGEColors.surfaceSecondary)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                Button {
                    send(.callTaxiTapped)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .foregroundStyle(BIRGEColors.blue)
                            .font(.system(size: 20))
                        
                        Text("Стандарт  ·  ~4 мин  ·  от 900₸")
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(
            Color.white
                .clipShape(
                    .rect(
                        topLeadingRadius: 24,
                        topTrailingRadius: 24
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
