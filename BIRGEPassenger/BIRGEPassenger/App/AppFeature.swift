//
//  AppFeature.swift
//  BIRGEPassenger
//

import BIRGECore
import ComposableArchitecture
import Foundation

private enum AppCancelID {
    static let authSession = "AppFeature.authSession"
}

// MARK: - AppFeature

@Reducer
struct AppFeature {

    @ObservableState
    enum State: Equatable {
        case unauthenticated(OTPFeature.State)
        case authenticated(PassengerAppFeature.State)

        init() {
            let token = try? KeychainClient.liveValue.loadAccessToken()
            if token != nil {
                self = .authenticated(PassengerAppFeature.State())
            } else {
                self = .unauthenticated(OTPFeature.State())
            }
        }
    }

    @CasePathable
    enum Action: Sendable {
        case task
        case authSessionEventReceived(AuthSessionEvent)
        case otp(OTPFeature.Action)
        case passengerApp(PassengerAppFeature.Action)
    }

    @Dependency(\.authSessionClient) var authSessionClient
    @Dependency(\.keychainClient) var keychainClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                let authSessionClient = self.authSessionClient
                return .run { send in
                    for await event in authSessionClient.events() {
                        await send(.authSessionEventReceived(event))
                    }
                }
                .cancellable(id: AppCancelID.authSession, cancelInFlight: true)

            case let .authSessionEventReceived(.authExpired(message)):
                try? keychainClient.clearAuthTokens()
                var otpState = OTPFeature.State()
                otpState.errorMessage = message
                state = .unauthenticated(otpState)
                return .none

            case .otp(.delegate(.authenticated(_))):
                state = .authenticated(PassengerAppFeature.State())
                return .none

            case .otp:
                return .none

            case .passengerApp(.delegate(.loggedOut)):
                try? keychainClient.clearAuthTokens()
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
