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
        case delegate(Delegate)

        // Internal
        case _otpRequestSucceeded
        case _otpRequestFailed(String)
        case _verifySucceeded(role: String)
        case _verifyFailed(String)

        @CasePathable
        enum Delegate: Sendable {
            case authenticated(role: String)
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

            case .verifyTapped:
                guard state.otpCode.count == 6 else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let phone = state.phoneNumber
                let code = state.otpCode
                let saveToKeychain = keychainClient.save
                let accessTokenKey = KeychainClient.Keys.accessToken
                let refreshTokenKey = KeychainClient.Keys.refreshToken
                let userIDKey = KeychainClient.Keys.userID
                return .run { send in
                    let response = try await authClient.verifyOTP(phone, code)
                    try saveToKeychain(accessTokenKey, response.accessToken)
                    try saveToKeychain(refreshTokenKey, response.refreshToken)
                    try saveToKeychain(userIDKey, response.userId)
                    await send(._verifySucceeded(role: response.role))
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

            case let ._verifySucceeded(role):
                state.isLoading = false
                return .send(.delegate(.authenticated(role: role)))

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
