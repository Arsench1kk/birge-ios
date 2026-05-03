import ComposableArchitecture
import SwiftUI

// MARK: - Onboarding Slide Data

private struct OnboardingSlide {
    let symbol: String
    let symbolColor: Color
    let title: String
    let body: String
}

private let slides: [OnboardingSlide] = [
    .init(
        symbol: "arrow.down.forward.and.arrow.up.backward",
        symbolColor: BIRGEColors.brandPrimary,
        title: "Экономия до 40%",
        body: "Фиксированные маршруты — меньше пробок, меньше цена. Никаких сюрпризов."
    ),
    .init(
        symbol: "brain",
        symbolColor: Color.purple,
        title: "AI подбирает маршрут",
        body: "Умный алгоритм анализирует ваши поездки и предлагает лучший коридор."
    ),
    .init(
        symbol: "leaf.fill",
        symbolColor: Color(red: 0.06, green: 0.72, blue: 0.51),
        title: "Меньше машин — чище город",
        body: "Carpooling снижает выбросы CO₂ и разгружает алматинские пробки."
    )
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            BIRGEColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Slides via TabView
                TabView(selection: Binding(
                    get: { store.currentPage },
                    set: { store.send(.pageChanged($0)) }
                )) {
                    ForEach(slides.indices, id: \.self) { index in
                        slideContent(slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: store.currentPage)

                // ── Dot Indicators
                dotsIndicator
                    .padding(.bottom, BIRGELayout.l)

                // ── Buttons
                bottomButtons
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.bottom, BIRGELayout.xl)
            }
        }
    }

    // MARK: - Slide Content

    private func slideContent(_ slide: OnboardingSlide) -> some View {
        VStack(spacing: BIRGELayout.xl) {
            Spacer()

            // Illustration circle + SF Symbol
            ZStack {
                Circle()
                    .fill(slide.symbolColor.opacity(0.1))
                    .frame(width: 180, height: 180)
                Circle()
                    .fill(slide.symbolColor.opacity(0.06))
                    .frame(width: 140, height: 140)
                Image(systemName: slide.symbol)
                    .font(.system(size: 70, weight: .medium))
                    .foregroundStyle(slide.symbolColor)
                    .symbolRenderingMode(.hierarchical)
            }

            // Text content
            VStack(spacing: BIRGELayout.s) {
                Text(slide.title)
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(slide.body)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, BIRGELayout.m)
            }

            Spacer()
        }
    }

    // MARK: - Dots

    private var dotsIndicator: some View {
        HStack(spacing: BIRGELayout.xxs) {
            ForEach(0..<store.totalPages, id: \.self) { index in
                let isActive = index == store.currentPage
                Capsule()
                    .fill(isActive ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary.opacity(0.4))
                    .frame(width: isActive ? 24 : 8, height: 8)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                        value: store.currentPage
                    )
            }
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: BIRGELayout.xs) {
            let isLast = store.currentPage == store.totalPages - 1

            BIRGEPrimaryButton(
                title: isLast ? "Начать" : "Далее"
            ) {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                    _ = store.send(.nextTapped)
                }
            }

            if !isLast {
                Button("Пропустить") {
                    store.send(.skipTapped)
                }
                .font(BIRGEFonts.body)
                .foregroundStyle(BIRGEColors.textSecondary)
                .birgeTapTarget()
            }
        }
    }
}

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
