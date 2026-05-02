import ComposableArchitecture
import SwiftUI

@ViewAction(for: RideCompleteFeature.self)
struct RideCompleteView: View {
    @Bindable var store: StoreOf<RideCompleteFeature>

    private enum Texts {
        static let commentPlaceholder = "Оставить комментарий..."
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // TOP SECTION
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 80, height: 80)
                            .scaleEffect(store.isCheckmarkVisible ? 1.0 : 0.3)
                            .opacity(store.isCheckmarkVisible ? 1.0 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: store.isCheckmarkVisible)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                            .scaleEffect(store.isCheckmarkVisible ? 1.0 : 0.3)
                            .opacity(store.isCheckmarkVisible ? 1.0 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: store.isCheckmarkVisible)
                    }
                    .padding(.top, 48)
                    
                    Text("Поездка завершена!")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 16)
                    
                    Text("Спасибо, что выбрали BIRGE")
                        .font(.system(size: 15))
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .padding(.top, 4)
                }
                
                // RIDE SUMMARY CARD
                VStack(spacing: 0) {
                    HStack {
                        Text("Алатау → Есентай")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                    }
                    .padding(.bottom, 12)
                    
                    Divider()
                        .padding(.bottom, 12)
                    
                    summaryRow(label: "Стоимость", value: "1 850₸", icon: "🔵")
                    summaryRow(label: "Время в пути", value: "34 мин")
                    summaryRow(label: "Дистанция", value: "17.8 км")
                    summaryRow(label: "Водитель", value: "Азамат К.", icon: "⭐")
                    
                    Divider()
                        .padding(.vertical, 12)
                    
                    HStack {
                        Text("🟡 Оплачено через Kaspi Pay")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 32)
                
                // RATING SECTION
                VStack(spacing: 16) {
                    Text("Оцените поездку с Азаматом К.")
                        .font(.system(size: 17, weight: .semibold))
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= store.rating ? "star.fill" : "star")
                                .foregroundStyle(star <= store.rating ? Color.yellow : Color.gray.opacity(0.3))
                                .font(.system(size: 36))
                                .onTapGesture {
                                    send(.ratingSelected(star))
                                }
                                .scaleEffect(star <= store.rating ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3), value: store.rating)
                        }
                    }
                    
                    if store.rating > 0 {
                        GeometryReader { geometry in
                            tagRows(store.tags, width: geometry.size.width)
                        }
                        .frame(height: 120) // Provide adequate height for wrapping layout
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))

                        TextField(
                            Texts.commentPlaceholder,
                            text: Binding(
                                get: { store.comment },
                                set: { send(.commentChanged($0)) }
                            ),
                            axis: .vertical
                        )
                        .textFieldStyle(.plain)
                        .lineLimit(2...4)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.top, 32)
                .padding(.horizontal, 16)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.white)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    send(.doneTapped)
                } label: {
                    Text("Готово")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(BIRGEColors.blue)
                        .cornerRadius(16)
                }
                
                Button {
                    // Secondary action placeholder
                } label: {
                    Text("Сообщить о проблеме")
                        .font(.system(size: 15))
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(Color.white)
        }
        .onAppear {
            send(.onAppear)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    private func summaryRow(label: String, value: String, icon: String? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(BIRGEColors.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 15))
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private func tagRows(_ tags: [String], width: CGFloat) -> some View {
        var rows: [[String]] = [[]]
        var currentWidth: CGFloat = 0
        
        for tag in tags {
            // Approximate width: each character ~9pt + 28pt padding
            let tagWidth = CGFloat(tag.count * 9 + 28)
            if currentWidth + tagWidth > width {
                rows.append([tag])
                currentWidth = tagWidth
            } else {
                rows[rows.count - 1].append(tag)
                currentWidth += tagWidth + 8
            }
        }
        
        return VStack(alignment: .center, spacing: 8) {
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    ForEach(rows[i], id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func tagChip(_ tag: String) -> some View {
        let isSelected = store.selectedTags.contains(tag)
        Text(tag)
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? BIRGEColors.blue : Color(.systemGray6))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .cornerRadius(20)
            .onTapGesture {
                send(.tagToggled(tag))
            }
            .animation(.spring(response: 0.3), value: store.selectedTags)
    }
}

#Preview {
    RideCompleteView(
        store: Store(initialState: RideCompleteFeature.State()) {
            RideCompleteFeature()
        }
    )
}
