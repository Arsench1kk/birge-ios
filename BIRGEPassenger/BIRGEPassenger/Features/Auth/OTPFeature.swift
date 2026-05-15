//
//  OTPFeature.swift
//  BIRGEPassenger
//

import ComposableArchitecture
import Foundation

// MARK: - OTP Errors

enum OTPError: LocalizedError, Sendable {
    case invalidCode
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Неверный код. Попробуйте ещё раз."
        case .networkError:
            return "Ошибка сети. Попробуйте позже."
        }
    }
}

struct OTPAuthentication: Equatable, Sendable {
    let role: String
    let phone: String
}

// MARK: - OTPFeature

@Reducer
struct OTPFeature {

    @ObservableState
    struct State: Equatable {
        var phoneNumber: String = ""
        var otpCode: String = ""
        var step: Step = .phone
        var isLoading: Bool = false
        var errorMessage: String? = nil

        enum Step: Equatable, Sendable {
            case phone
            case code
        }
    }

    @CasePathable
    enum Action: Sendable {
        case phoneChanged(String)
        case sendOTPTapped
        case otpChanged(String)
        case verifyTapped
        case changePhoneTapped
        case delegate(Delegate)

        // Internal
        case _otpRequestSucceeded
        case _otpRequestFailed(String)
        case _verifySucceeded(OTPAuthentication)
        case _verifyFailed(String)

        @CasePathable
        enum Delegate: Sendable {
            case authenticated(OTPAuthentication)
        }
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.keychainClient) var keychainClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case let .phoneChanged(phone):
                state.phoneNumber = phone
                state.errorMessage = nil
                return .none

            case .sendOTPTapped:
                guard !state.phoneNumber.isEmpty else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let phone = state.phoneNumber
                return .run { send in
                    try await authClient.requestOTP(phone)
                    await send(._otpRequestSucceeded)
                } catch: { error, send in
                    await send(._otpRequestFailed(error.localizedDescription))
                }

            case let .otpChanged(code):
                state.otpCode = code
                state.errorMessage = nil
                return .none

            case .changePhoneTapped:
                // Return to phone step so the user can edit their number.
                // phoneNumber is preserved so they don't retype from scratch.
                state.step = .phone
                state.otpCode = ""
                state.errorMessage = nil
                return .none

            case .verifyTapped:
                guard state.otpCode.count == 6 else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let phone = state.phoneNumber
                let code = state.otpCode
                return .run { [keychainClient] send in
                    let response = try await authClient.verifyOTP(phone, code)
                    try keychainClient.save("birge_access_token", response.accessToken)
                    try keychainClient.save("birge_refresh_token", response.refreshToken)
                    try keychainClient.save("birge_user_id", response.userId)
                    await send(._verifySucceeded(OTPAuthentication(role: response.role, phone: phone)))
                } catch: { error, send in
                    await send(._verifyFailed(error.localizedDescription))
                }

            case ._otpRequestSucceeded:
                state.isLoading = false
                state.step = .code
                return .none

            case let ._otpRequestFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let ._verifySucceeded(authentication):
                state.isLoading = false
                return .send(.delegate(.authenticated(authentication)))

            case let ._verifyFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
