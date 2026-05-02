//
//  AuthClient.swift
//  BIRGEPassenger
//
//  Created by Арсен Абдухалық on 22.04.2026.
//

import BIRGECore
import ComposableArchitecture
import Foundation

// MARK: - Auth Response (matches Vapor AuthResponseDTO exactly)

struct AuthResponse: Equatable, Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let role: String
    let userId: String
}

struct CurrentUser: Equatable, Decodable, Sendable {
    let id: String
    let phone: String
    let email: String?
    let role: String
    let name: String?
}

// MARK: - Auth Errors

enum AuthError: LocalizedError, Sendable {
    case requestFailed
    case verificationFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .requestFailed:
            "Не удалось отправить код. Попробуйте позже."
        case .verificationFailed:
            "Неверный код. Попробуйте ещё раз."
        case .invalidResponse:
            "Некорректный ответ сервера."
        }
    }
}

// MARK: - AuthClient

struct AuthClient: Sendable {
    var requestOTP: @Sendable (String) async throws -> Void
    var verifyOTP: @Sendable (String, String) async throws -> AuthResponse
    var currentUser: @Sendable () async throws -> CurrentUser
}

// MARK: - DependencyKey

extension AuthClient: DependencyKey {
    static let liveValue = AuthClient(
        requestOTP: { phone in
            try await APIClient.liveValue.requestOTP(phone)
        },
        verifyOTP: { phone, code in
            let response = try await APIClient.liveValue.verifyOTP(phone, code)
            return AuthResponse(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                role: response.role,
                userId: response.userID
            )
        },
        currentUser: {
            let user = try await APIClient.liveValue.currentUser()
            return CurrentUser(
                id: user.id,
                phone: user.phone,
                email: user.email,
                role: user.role,
                name: user.name
            )
        }
    )

    static let testValue = AuthClient(
        requestOTP: { _ in
            try await Task.sleep(for: .milliseconds(500))
        },
        verifyOTP: { _, _ in
            try await Task.sleep(for: .milliseconds(500))
            return AuthResponse(
                accessToken: "test-access-token",
                refreshToken: "test-refresh-token",
                role: "passenger",
                userId: "test-user-id"
            )
        },
        currentUser: {
            CurrentUser(
                id: "test-user-id",
                phone: "+77771234567",
                email: nil,
                role: "passenger",
                name: "Test User"
            )
        }
    )
}

// MARK: - DependencyValues

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
