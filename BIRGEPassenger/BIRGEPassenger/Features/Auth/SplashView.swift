import ComposableArchitecture
import SwiftUI

// MARK: - SplashView

@ViewAction(for: SplashFeature.self)
struct SplashView: View {
    let store: StoreOf<SplashFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false
    @State private var cardAppeared = false

    var body: some View {
        ZStack {
            // BACKGROUND — радиальный синий градиент
            RadialGradient(
                colors: [
                    BIRGEColors.brandPrimary,
                    BIRGEColors.brandPrimary.opacity(0.7)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // PULSE RINGS
            if !reduceMotion {
                ForEach([0, 1, 2], id: \.self) { index in
                    pulseRing(delay: Double(index) * 0.7)
                }
            }

            // CENTER CARD
            VStack(spacing: BIRGELayout.xs) {
                Image(systemName: "bolt.car.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)

                Text("BIRGE")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .kerning(-1)

                Rectangle()
                    .fill(.white.opacity(0.45))
                    .frame(width: 40, height: 2)
                    .cornerRadius(1)

                Text("Поехали вместе")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(.horizontal, BIRGELayout.xxxl)
            .padding(.vertical, BIRGELayout.xxl)
            .liquidGlass(.card, tint: .white.opacity(0.08))
            .scaleEffect(cardAppeared ? 1.0 : 0.92)
            .opacity(cardAppeared ? 1.0 : 0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75),
                value: cardAppeared
            )

            // FOOTER
            VStack {
                Spacer()
                Text("© 2026 BIRGE")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, BIRGELayout.m)
            }
        }
        .onAppear {
            cardAppeared = true
            if !reduceMotion {
                isAnimating = true
            }
            send(.onAppear)
        }
    }

    // MARK: - Pulse Ring

    private func pulseRing(delay: Double) -> some View {
        Circle()
            .stroke(.white.opacity(0.15), lineWidth: 1)
            .frame(width: 100, height: 100)
            .scaleEffect(isAnimating ? 5.0 : 1.0)
            .opacity(isAnimating ? 0 : 0.15)
            .animation(
                .easeOut(duration: 2.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: isAnimating
            )
    }
}

#Preview {
    SplashView(
        store: Store(initialState: SplashFeature.State()) {
            SplashFeature()
        }
    )
}
