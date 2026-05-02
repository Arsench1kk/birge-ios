import ComposableArchitecture
import SwiftUI

@ViewAction(for: RideRequestFeature.self)
struct RideRequestView: View {
    @Bindable var store: StoreOf<RideRequestFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    send(.backTapped)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                }

                Spacer()
            }
            .padding(.horizontal, BIRGELayout.s)
            .padding(.top, BIRGELayout.xs)
            .padding(.bottom, BIRGELayout.s)

            // ADDRESS SECTION
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: BIRGELayout.xs) {
                    Circle()
                        .fill(BIRGEColors.success)
                        .frame(width: BIRGELayout.xxs, height: BIRGELayout.xxs)
                    Text(store.origin)
                        .font(BIRGEFonts.body)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
                .padding(.vertical, BIRGELayout.xxs)
                
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
                    .padding(.leading, BIRGELayout.xxxs)
                
                HStack(spacing: BIRGELayout.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .font(BIRGEFonts.body)
                    TextField(
                        "Куда едем?",
                        text: Binding(
                            get: { store.destination },
                            set: { send(.destinationChanged($0)) }
                        )
                    )
                        .font(BIRGEFonts.bodyMedium)
                }
                .padding(.vertical, BIRGELayout.xxs)
            }
            .padding(BIRGELayout.s)
            .birgeCard()
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            .padding(.horizontal, BIRGELayout.s)
            .padding(.bottom, BIRGELayout.l)
            
            // RIDE TIER SELECTOR
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BIRGELayout.xs) {
                    ForEach(RideRequestFeature.RideTier.allCases, id: \.self) { tier in
                        tierCard(for: tier)
                    }
                }
                .padding(.horizontal, BIRGELayout.s)
                .padding(.bottom, BIRGELayout.l)
            }
            
            // ROUTE SUMMARY ROW
            Text("📍 Алатау → Есентай  ·  18 км  ·  ~35 мин")
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .padding(.bottom, BIRGELayout.s)

            if let errorMessage = store.errorMessage {
                BIRGEToast(message: errorMessage, style: .error)
                    .padding(.horizontal, BIRGELayout.s)
                    .padding(.bottom, BIRGELayout.s)
            }
            
            Spacer()
        }
        .background(BIRGEColors.background)
        .safeAreaInset(edge: .bottom) {
            BIRGEPrimaryButton(
                title: store.isLoading ? "Создаём поездку..." : "Найти водителя · \(store.fare)₸",
                isLoading: store.isLoading
            ) {
                send(.findDriverTapped)
            }
            .disabled(store.isLoading)
            .padding(.horizontal, BIRGELayout.s)
            .padding(.bottom, BIRGELayout.s)
            .background(BIRGEColors.background)
        }
        .navigationTitle("Новая поездка")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    func tierCard(for tier: RideRequestFeature.RideTier) -> some View {
        let isSelected = store.selectedTier == tier
        
        Button {
            withAnimation(.spring(response: 0.3)) {
                _ = send(.tierSelected(tier))
            }
        } label: {
            VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                HStack(alignment: .top) {
                    Image(systemName: icon(for: tier))
                        .font(BIRGEFonts.title)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                    Spacer()
                    if tier == .corridor {
                        Text("−52%")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.textOnBrand)
                            .padding(.horizontal, BIRGELayout.xxs)
                            .padding(.vertical, BIRGELayout.xxxs)
                            .background(BIRGEColors.success)
                            .cornerRadius(BIRGELayout.radiusXS)
                    }
                }
                
                Spacer()
                
                Text(tier.rawValue)
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(subtitle(for: tier))
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                
                Text("\(store.fares[tier] ?? 0)₸")
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(.primary)
                    .padding(.top, BIRGELayout.xxxs)
            }
            .padding(BIRGELayout.s)
            .frame(minWidth: 132, maxWidth: 180, minHeight: 132, alignment: .leading)
            .background(isSelected ? BIRGEColors.brandPrimary.opacity(0.08) : BIRGEColors.surfacePrimary)
            .cornerRadius(BIRGELayout.radiusM)
            .overlay(
                RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                    .stroke(isSelected ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary.opacity(0.22), lineWidth: isSelected ? 2 : 1)
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
