import ComposableArchitecture
import SwiftUI

// MARK: - SplashView

struct SplashView: View {
    let store: StoreOf<SplashFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentAppeared = false

    var body: some View {
        ZStack {
            BIRGEColors.passengerBackground
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: BIRGELayout.s) {
                    brandBlock
                    routeMotif
                        .padding(.top, BIRGELayout.xxs)
                }
                .padding(.horizontal, BIRGELayout.m)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared || reduceMotion ? 0 : 10)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.45),
                    value: contentAppeared
                )

                Spacer()

                startButton
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.bottom, BIRGELayout.l)
            }
        }
        .onAppear {
            contentAppeared = true
            store.send(.onAppear)
        }
    }

    private var brandBlock: some View {
        VStack(spacing: BIRGELayout.xxs) {
            Image("BIRGELogoPassenger")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .accessibilityLabel("BIRGE passenger logo")

            Image("BIRGEWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 142)
                .padding(.top, -BIRGELayout.xxxs)
                .accessibilityLabel("BIRGE")

            Text("Маршруты по подписке")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.textPrimary)
                .padding(.top, BIRGELayout.xxxs)

            Text("Для регулярных поездок по Алматы")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
        .multilineTextAlignment(.center)
    }

    private var routeMotif: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(BIRGEColors.routeCanvasBackground)

            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
                .padding(.horizontal, BIRGELayout.s)
                .padding(.vertical, BIRGELayout.l)

            Rectangle()
                .fill(BIRGEColors.brandPrimary)
                .frame(height: 4)
                .clipShape(Capsule())
                .padding(.horizontal, 52)
                .rotationEffect(.degrees(-8))

            Circle()
                .fill(BIRGEColors.brandPrimary)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(BIRGEColors.passengerSurface, lineWidth: 4))
                .position(x: 40, y: 82)

            Circle()
                .fill(BIRGEColors.brandPrimary)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(BIRGEColors.passengerSurface, lineWidth: 4))
                .position(x: 295, y: 52)

            Circle()
                .fill(BIRGEColors.brandPrimary.opacity(0.42))
                .frame(width: 9, height: 9)
                .position(x: 116, y: 72)

            Circle()
                .fill(BIRGEColors.brandPrimary.opacity(0.42))
                .frame(width: 9, height: 9)
                .position(x: 220, y: 62)
        }
        .frame(height: 134)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .accessibilityHidden(true)
    }

    private var startButton: some View {
        Text("Начать")
            .font(BIRGEFonts.bodyMedium)
            .foregroundStyle(BIRGEColors.textOnBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(BIRGEColors.brandPrimary)
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }
}

#Preview {
    SplashView(
        store: Store(initialState: SplashFeature.State()) {
            SplashFeature()
        }
    )
}
