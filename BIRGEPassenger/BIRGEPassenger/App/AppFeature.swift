//
//  AppFeature.swift
//  BIRGEPassenger
//

import ComposableArchitecture
import Foundation

// MARK: - AppFeature

@Reducer
struct AppFeature {

    @ObservableState
    enum State: Equatable {
        case splash(SplashFeature.State)
        case onboarding(OnboardingFeature.State)
        case unauthenticated(OTPFeature.State)
        case authenticated(PassengerAppFeature.State)

        init() {
            self = .splash(SplashFeature.State())
        }
    }

    @CasePathable
    enum Action: Sendable {
        case splash(SplashFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case otp(OTPFeature.Action)
        case passengerApp(PassengerAppFeature.Action)
    }

    @Dependency(\.keychainClient) var keychainClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // Splash → Onboarding или Authenticated
            case .splash(.delegate(.splashFinished)):
                let token = try? keychainClient.load("birge_access_token")
                if token != nil {
                    state = .authenticated(PassengerAppFeature.State())
                } else {
                    state = .onboarding(OnboardingFeature.State())
                }
                return .none

            case .splash:
                return .none

            // Onboarding → OTP
            case .onboarding(.delegate(.onboardingFinished)):
                state = .unauthenticated(OTPFeature.State())
                return .none

            case .onboarding:
                return .none

            // OTP → Authenticated
            case .otp(.delegate(.authenticated(_))):
                state = .authenticated(PassengerAppFeature.State())
                return .none

            case .otp:
                return .none

            // Logout → Unauthenticated
            case .passengerApp(.delegate(.loggedOut)):
                try? keychainClient.delete("birge_access_token")
                try? keychainClient.delete("birge_refresh_token")
                try? keychainClient.delete("birge_user_id")
                state = .unauthenticated(OTPFeature.State())
                return .none

            case .passengerApp:
                return .none
            }
        }
        .ifCaseLet(\.splash, action: \.splash) {
            SplashFeature()
        }
        .ifCaseLet(\.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifCaseLet(\.unauthenticated, action: \.otp) {
            OTPFeature()
        }
        .ifCaseLet(\.authenticated, action: \.passengerApp) {
            PassengerAppFeature()
        }
    }
}
