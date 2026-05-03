import ComposableArchitecture
import SwiftUI

@ViewAction(for: SearchingFeature.self)
struct SearchingView: View {
    @Bindable var store: StoreOf<SearchingFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            BIRGEColors.brandPrimary
            .ignoresSafeArea()
            
            // Center Content
            VStack(spacing: 0) {
                // RADAR ANIMATION
                ZStack {
                    if reduceMotion {
                        ProgressView()
                            .tint(BIRGEColors.textOnBrand)
                            .scaleEffect(1.4)
                    } else {
                        radarRing(size: 180, opacity: 0.15, delay: 0.6)
                        radarRing(size: 130, opacity: 0.35, delay: 0.3)
                        radarRing(size: 80, opacity: 0.6, delay: 0)
                    }

                    Circle()
                        .fill(BIRGEColors.surfacePrimary)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(BIRGEFonts.title)
                                .foregroundStyle(BIRGEColors.brandPrimary)
                        )
                }
                .padding(.bottom, BIRGELayout.xl)
                
                // STATUS TEXT
                Text("Ищем водителя")
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(width: 250, alignment: .center)
                
                Text(store.statusText)
                    .font(BIRGEFonts.body)
                    .foregroundStyle(BIRGEColors.textOnBrand.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.top, BIRGELayout.xxxs)

                if let errorMessage = store.errorMessage {
                    BIRGEToast(message: errorMessage, style: .error)
                        .padding(.horizontal, BIRGELayout.l)
                        .padding(.top, BIRGELayout.xs)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BIRGESecondaryButton(title: store.isCancelling ? "Отменяем..." : "Отменить поиск", isLoading: store.isCancelling) {
                send(.cancelTapped)
            }
            .disabled(store.isCancelling)
            .padding(.horizontal, BIRGELayout.s)
            .padding(.bottom, BIRGELayout.s)
        }
        .onAppear {
            isAnimating = true
            send(.onAppear)
        }
        .onDisappear {
            send(.onDisappear)
        }
        .navigationBarHidden(true)
    }

    private func radarRing(size: CGFloat, opacity: Double, delay: Double) -> some View {
        Circle()
            .fill(BIRGEColors.textOnBrand.opacity(opacity))
            .frame(width: size, height: size)
            .scaleEffect(isAnimating ? 1.8 : 1.0)
            .opacity(isAnimating ? 0 : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: isAnimating
            )
    }
}

#Preview {
    SearchingView(
        store: Store(initialState: SearchingFeature.State(rideId: "preview-ride")) {
            SearchingFeature()
        }
    )
}
