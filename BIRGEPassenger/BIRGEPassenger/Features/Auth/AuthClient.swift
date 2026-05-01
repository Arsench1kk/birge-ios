//
//  AuthClient.swift
//  BIRGEPassenger
//
//  Created by Арсен Абдухалық on 22.04.2026.
//

import ComposableArchitecture
import Foundation

// MARK: - Auth Response (matches Vapor AuthResponseDTO exactly)

struct AuthResponse: Equatable, Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let role: String
    let userId: String
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
}

// MARK: - DependencyKey

extension AuthClient: DependencyKey {
    static let liveValue: AuthClient = {
        #if DEBUG
        let baseURL = URL(string: "http://localhost:8080/api/v1")!
        #else
        let baseURL = URL(string: "https://api.birge.kz/api/v1")!
        #endif

        let decoder = JSONDecoder()

        return AuthClient(
            requestOTP: { phone in
                var request = URLRequest(
                    url: baseURL.appendingPathComponent("auth/otp/request")
                )
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(["phone": phone])

                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode)
                else {
                    throw AuthError.requestFailed
                }
            },
            verifyOTP: { phone, code in
                var request = URLRequest(
                    url: baseURL.appendingPathComponent("auth/otp/verify")
                )
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: String] = ["phone": phone, "code": code]
                request.httpBody = try JSONEncoder().encode(body)

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode)
                else {
                    throw AuthError.verificationFailed
                }

                return try decoder.decode(AuthResponse.self, from: data)
            }
        )
    }()

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
