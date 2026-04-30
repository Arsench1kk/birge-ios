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
        case unauthenticated(OTPFeature.State)
        case authenticated(PassengerAppFeature.State)

        init() {
            let token = UserDefaults.standard.string(forKey: "birge_auth_token")
            if token != nil {
                self = .authenticated(PassengerAppFeature.State())
            } else {
                self = .unauthenticated(OTPFeature.State())
            }
        }
    }

    @CasePathable
    enum Action: Sendable {
        case otp(OTPFeature.Action)
        case passengerApp(PassengerAppFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .otp(.delegate(.authenticated)):
                state = .authenticated(PassengerAppFeature.State())
                return .none

            case .otp:
                return .none

            case .passengerApp(.delegate(.loggedOut)):
                state = .unauthenticated(OTPFeature.State())
                return .none

            case .passengerApp:
                return .none
            }
        }
        .ifCaseLet(\.unauthenticated, action: \.otp) {
            OTPFeature()
        }
        .ifCaseLet(\.authenticated, action: \.passengerApp) {
            PassengerAppFeature()
        }
    }
}
