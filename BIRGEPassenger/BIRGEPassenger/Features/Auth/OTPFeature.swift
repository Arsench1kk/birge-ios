//
//  OTPFeature.swift
//  BIRGEPassenger
//

import ComposableArchitecture
import Foundation

// MARK: - Mock Auth Client

struct MockAuthClient: Sendable {
    var requestOTP: @Sendable (String) async throws -> Void
    var verifyOTP: @Sendable (String, String) async throws -> String
}

extension MockAuthClient: DependencyKey {
    static let liveValue = MockAuthClient(
        requestOTP: { _ in
            try await Task.sleep(for: .milliseconds(1500))
        },
        verifyOTP: { _, code in
            try await Task.sleep(for: .milliseconds(1500))
            guard code.count == 6, code.allSatisfy(\.isNumber) else {
                throw OTPError.invalidCode
            }
            return "mock_token_123"
        }
    )

    static let previewValue = MockAuthClient(
        requestOTP: { _ in
            try await Task.sleep(for: .milliseconds(1500))
        },
        verifyOTP: { _, code in
            try await Task.sleep(for: .milliseconds(1500))
            guard code.count == 6, code.allSatisfy(\.isNumber) else {
                throw OTPError.invalidCode
            }
            return "mock_token_123"
        }
    )

    static let testValue = MockAuthClient(
        requestOTP: { _ in },
        verifyOTP: { _, _ in "mock_token_123" }
    )
}

extension DependencyValues {
    var mockAuthClient: MockAuthClient {
        get { self[MockAuthClient.self] }
        set { self[MockAuthClient.self] = newValue }
    }
}

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
        case _verifySucceeded(String)
        case _verifyFailed(String)

        @CasePathable
        enum Delegate: Sendable {
            case authenticated
        }
    }

    @Dependency(\.mockAuthClient) var authClient

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
                return .run { send in
                    let token = try await authClient.verifyOTP(phone, code)
                    await send(._verifySucceeded(token))
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

            case let ._verifySucceeded(token):
                state.isLoading = false
                UserDefaults.standard.set(token, forKey: "birge_auth_token")
                return .send(.delegate(.authenticated))

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
