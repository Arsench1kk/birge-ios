import ComposableArchitecture
import SwiftUI

@ViewAction(for: RideCompleteFeature.self)
struct RideCompleteView: View {
    @Bindable var store: StoreOf<RideCompleteFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isReportSheetPresented = false
    @State private var reportIssueText = ""
    @State private var isReportSuccessVisible = false

    private enum Texts {
        static let commentPlaceholder = "Оставить комментарий..."
        static let reportIssue = "Сообщить о проблеме"
        static let reportTitle = "Опишите проблему"
        static let reportPlaceholder = "Что случилось?"
        static let submitReport = "Отправить"
        static let cancelReport = "Отмена"
        static let reportSuccess = "Спасибо, мы получили сообщение"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // TOP SECTION
                VStack(spacing: 0) {
                    ZStack {
                        // Pulse ring
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 110, height: 110)
                            .scaleEffect(store.isCheckmarkVisible ? 1.25 : 0.8)
                            .opacity(store.isCheckmarkVisible ? 0 : 0.6)
                            .animation(
                                reduceMotion ? nil : .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                                value: store.isCheckmarkVisible
                            )

                        // Main circle
                        Circle()
                            .fill(BIRGEColors.success)
                            .frame(width: 80, height: 80)
                            .scaleEffect(store.isCheckmarkVisible ? 1.0 : 0.3)
                            .opacity(store.isCheckmarkVisible ? 1.0 : 0)
                            .animation(
                                reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6),
                                value: store.isCheckmarkVisible
                            )

                        // Checkmark icon
                        Image(systemName: "checkmark")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(store.isCheckmarkVisible ? 1.0 : 0.3)
                            .opacity(store.isCheckmarkVisible ? 1.0 : 0)
                            .animation(
                                reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6).delay(0.1),
                                value: store.isCheckmarkVisible
                            )
                    }
                    .padding(.top, BIRGELayout.xxxl)
                    
                    Text("Поездка завершена!")
                        .font(BIRGEFonts.title)
                        .padding(.top, BIRGELayout.s)
                    
                    Text("Спасибо, что выбрали BIRGE")
                        .font(BIRGEFonts.body)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .padding(.top, BIRGELayout.xxxs)
                }
                
                // RIDE SUMMARY CARD
                VStack(spacing: 0) {
                    HStack {
                        Text("Алатау → Есентай")
                            .font(BIRGEFonts.bodyMedium)
                        Spacer()
                    }
                    .padding(.bottom, BIRGELayout.xs)
                    
                    Divider()
                        .padding(.bottom, BIRGELayout.xs)
                    
                    summaryRow(label: "Стоимость", value: "1 850₸", symbol: "circle.fill", symbolColor: BIRGEColors.brandPrimary)
                    summaryRow(label: "Время в пути", value: "34 мин", symbol: "clock.fill")
                    summaryRow(label: "Дистанция", value: "17.8 км", symbol: "arrow.forward.circle.fill")
                    summaryRow(label: "Водитель", value: "Азамат К.", symbol: "star.fill", symbolColor: .yellow)
                    
                    Divider()
                        .padding(.vertical, BIRGELayout.xs)
                    
                    HStack {
                        Label("Оплачено через Kaspi Pay", systemImage: "creditcard.fill")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.brandPrimary)
                        Spacer()
                    }
                }
                .padding(BIRGELayout.s)
                .birgeGlassCard()
                .padding(.horizontal, BIRGELayout.s)
                .padding(.top, BIRGELayout.xl)
                
                // RATING SECTION
                VStack(spacing: BIRGELayout.s) {
                    Text("Оцените поездку с Азаматом К.")
                        .font(BIRGEFonts.sectionTitle)
                    
                    HStack(spacing: BIRGELayout.xxs) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                                    _ = send(.ratingSelected(star))
                                }
                            } label: {
                                Image(systemName: star <= store.rating ? "star.fill" : "star")
                                    .foregroundStyle(star <= store.rating ? Color.yellow : BIRGEColors.textTertiary.opacity(0.42))
                                    .font(BIRGEFonts.heroNumber)
                                    .frame(width: BIRGELayout.minTapTarget, height: BIRGELayout.minTapTarget)
                                    .scaleEffect(star <= store.rating ? 1.08 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(star == 1 ? "1 звезда" : "\(star) звёзд")
                            .accessibilityAddTraits(star <= store.rating ? AccessibilityTraits.isSelected : AccessibilityTraits())
                        }
                    }
                    
                    if store.rating > 0 {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 132), spacing: BIRGELayout.xxs)],
                            spacing: BIRGELayout.xxs
                        ) {
                            ForEach(store.tags, id: \.self) { tag in
                                tagChip(tag)
                            }
                        }
                        .padding(.top, BIRGELayout.s)
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
                        .padding(BIRGELayout.xs)
                        .background(Color(.systemGray6))
                        .cornerRadius(BIRGELayout.radiusS)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.top, BIRGELayout.xl)
                .padding(.horizontal, BIRGELayout.s)
                
                Spacer(minLength: BIRGELayout.xxl)
            }
        }
        .background(BIRGEColors.background)
        .overlay(alignment: .bottom) {
            if isReportSuccessVisible {
                BIRGEToast(message: Texts.reportSuccess, style: .success)
                    .padding(.bottom, 104)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: BIRGELayout.xs) {
                BIRGEPrimaryButton(title: "Готово") {
                    send(.doneTapped)
                }
                
                Button {
                    isReportSheetPresented = true
                } label: {
                    Text(Texts.reportIssue)
                        .font(BIRGEFonts.body)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
                .birgeTapTarget()
            }
            .padding(.horizontal, BIRGELayout.s)
            .padding(.bottom, BIRGELayout.s)
            .background(BIRGEColors.background)
        }
        .onAppear {
            send(.onAppear)
        }
        .sheet(isPresented: $isReportSheetPresented) {
            ReportIssueView(
                text: $reportIssueText,
                onCancel: {
                    isReportSheetPresented = false
                },
                onSubmit: {
                    reportIssueText = ""
                    isReportSheetPresented = false
                    showReportSuccess()
                }
            )
        }
        .navigationBarBackButtonHidden(true)
    }

    private func showReportSuccess() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isReportSuccessVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.2)) {
                isReportSuccessVisible = false
            }
        }
    }
    
    @ViewBuilder
    private func summaryRow(
        label: String,
        value: String,
        symbol: String? = nil,
        symbolColor: Color = BIRGEColors.textSecondary
    ) -> some View {
        HStack {
            Text(label)
                .font(label == "Стоимость" ? BIRGEFonts.sectionTitle : BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)
            Spacer()
            HStack(spacing: BIRGELayout.xxxs) {
                Text(value)
                    .font(label == "Стоимость" ? BIRGEFonts.heroNumber : BIRGEFonts.subtext)
                    .foregroundStyle(label == "Стоимость" ? BIRGEColors.textPrimary : BIRGEColors.textSecondary)
                if let symbol = symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 12))
                        .foregroundStyle(symbolColor)
                }
            }
        }
        .padding(.bottom, BIRGELayout.xxs)
    }
    
    @ViewBuilder
    private func tagChip(_ tag: String) -> some View {
        let isSelected = store.selectedTags.contains(tag)
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                _ = send(.tagToggled(tag))
            }
        } label: {
            Text(tag)
                .font(BIRGEFonts.subtext)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, BIRGELayout.xs)
                .padding(.vertical, BIRGELayout.xxs)
                .background(isSelected ? BIRGEColors.brandPrimary : BIRGEColors.surfacePrimary)
                .foregroundStyle(isSelected ? BIRGEColors.textOnBrand : BIRGEColors.textPrimary)
                .cornerRadius(BIRGELayout.radiusFull)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}

private struct ReportIssueView: View {
    @Binding var text: String
    let onCancel: () -> Void
    let onSubmit: () -> Void

    private enum Texts {
        static let title = "Опишите проблему"
        static let placeholder = "Что случилось?"
        static let submit = "Отправить"
        static let cancel = "Отмена"
        static let counterLimit = 500
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                ZStack(alignment: .topLeading) {
                    TextEditor(
                        text: Binding(
                            get: { text },
                            set: { text = String($0.prefix(Texts.counterLimit)) }
                        )
                    )
                    .frame(minHeight: 140)
                    .padding(BIRGELayout.xxs)
                    .background(Color(.systemGray6))
                    .cornerRadius(BIRGELayout.radiusS)

                    if text.isEmpty {
                        Text(Texts.placeholder)
                            .font(BIRGEFonts.body)
                            .foregroundStyle(BIRGEColors.textSecondary)
                            .padding(.horizontal, BIRGELayout.xs)
                            .padding(.vertical, BIRGELayout.s)
                            .allowsHitTesting(false)
                    }
                }

                Text("\(text.count)/\(Texts.counterLimit)")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Spacer()
            }
            .padding(BIRGELayout.s)
            .navigationTitle(Texts.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Texts.cancel, action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Texts.submit, action: onSubmit)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    RideCompleteView(
        store: Store(initialState: RideCompleteFeature.State()) {
            RideCompleteFeature()
        }
    )
}
