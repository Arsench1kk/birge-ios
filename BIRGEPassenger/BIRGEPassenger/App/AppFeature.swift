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
            let token = try? KeychainClient.liveValue.load("birge_access_token")
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

    @Dependency(\.keychainClient) var keychainClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .otp(.delegate(.authenticated(_))):
                state = .authenticated(PassengerAppFeature.State())
                return .none

            case .otp:
                return .none

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
        .ifCaseLet(\.unauthenticated, action: \.otp) {
            OTPFeature()
        }
        .ifCaseLet(\.authenticated, action: \.passengerApp) {
            PassengerAppFeature()
        }
    }
}

