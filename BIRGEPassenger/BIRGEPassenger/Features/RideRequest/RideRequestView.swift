import ComposableArchitecture
import SwiftUI

@ViewAction(for: RideRequestFeature.self)
struct RideRequestView: View {
    @Bindable var store: StoreOf<RideRequestFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // ADDRESS SECTION
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(store.origin)
                        .font(.system(size: 15))
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
                .padding(.vertical, 8)
                
                // Vertical dashed line between rows
                Rectangle()
                    .fill(.clear)
                    .frame(width: 1, height: 20)
                    .background(
                        GeometryReader { geometry in
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                            }
                            .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3]))
                        }
                    )
                    .padding(.leading, 3.5)
                
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(BIRGEColors.blue)
                        .font(.system(size: 16))
                    TextField(
                        "Куда едем?",
                        text: Binding(
                            get: { store.destination },
                            set: { send(.destinationChanged($0)) }
                        )
                    )
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(.vertical, 8)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            
            // RIDE TIER SELECTOR
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RideRequestFeature.RideTier.allCases, id: \.self) { tier in
                        tierCard(for: tier)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
            // ROUTE SUMMARY ROW
            Text("📍 Алатау → Есентай  ·  18 км  ·  ~35 мин")
                .font(.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .padding(.bottom, 16)
            
            Spacer()
        }
        .background(Color.white)
        .safeAreaInset(edge: .bottom) {
            Button {
                send(.findDriverTapped)
            } label: {
                Text("Найти водителя · \(store.fare)₸")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(BIRGEColors.blue)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("Новая поездка")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func tierCard(for tier: RideRequestFeature.RideTier) -> some View {
        let isSelected = store.selectedTier == tier
        
        Button {
            withAnimation(.spring(response: 0.3)) {
                _ = send(.tierSelected(tier))
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: icon(for: tier))
                        .font(.system(size: 24))
                        .foregroundStyle(BIRGEColors.blue)
                    Spacer()
                    if tier == .corridor {
                        Text("−52%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Text(tier.rawValue)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(subtitle(for: tier))
                    .font(.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                
                Text("\(store.fares[tier] ?? 0)₸")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.top, 4)
            }
            .padding(16)
            .frame(width: 160, height: 140, alignment: .leading)
            .background(isSelected ? BIRGEColors.blue.opacity(0.06) : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? BIRGEColors.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    func icon(for tier: RideRequestFeature.RideTier) -> String {
        switch tier {
        case .standard: return "car.fill"
        case .corridor: return "person.3.fill"
        case .comfort: return "star.fill"
        }
    }
    
    func subtitle(for tier: RideRequestFeature.RideTier) -> String {
        switch tier {
        case .standard: return "~4 мин"
        case .corridor: return "07:30 · 3 места"
        case .comfort: return "~6 мин"
        }
    }
}

#Preview {
    RideRequestView(
        store: Store(initialState: RideRequestFeature.State()) {
            RideRequestFeature()
        }
    )
}
