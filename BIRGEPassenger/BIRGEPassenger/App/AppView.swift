import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            switch store.state {
            case .splash:
                if let splashStore = store.scope(state: \.splash, action: \.splash) {
                    SplashView(store: splashStore)
                        .transition(.opacity)
                }
            case .onboarding:
                if let onboardingStore = store.scope(state: \.onboarding, action: \.onboarding) {
                    OnboardingView(store: onboardingStore)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.04)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                }
            case .unauthenticated:
                if let otpStore = store.scope(state: \.unauthenticated, action: \.otp) {
                    OTPView(store: otpStore)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                }
            case .authenticated:
                if let passengerStore = store.scope(state: \.authenticated, action: \.passengerApp) {
                    PassengerAppView(store: passengerStore)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.04)),
                            removal: .opacity
                        ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: store.state.isSplash)
    }
}

// MARK: - State Helpers

private extension AppFeature.State {
    var isSplash: Bool {
        if case .splash = self { return true }
        return false
    }
}
