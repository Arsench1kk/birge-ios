import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            switch store.state {
            case .unauthenticated:
                if let otpStore = store.scope(state: \.unauthenticated, action: \.otp) {
                    OTPView(store: otpStore)
                }
            case .authenticated:
                if let passengerStore = store.scope(state: \.authenticated, action: \.passengerApp) {
                    PassengerAppView(store: passengerStore)
                }
            }
        }
        .onAppear {
            store.send(.task)
        }
    }
}
