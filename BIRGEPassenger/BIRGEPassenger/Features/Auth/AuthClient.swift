//
//  AuthClient.swift
//  BIRGEPassenger
//
//  Created by Арсен Абдухалық on 22.04.2026.
//

import ComposableArchitecture
import Foundation

// MARK: - JWT Model

struct JWT: Equatable, Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
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
    var verifyOTP: @Sendable (String, String) async throws -> JWT
}

// MARK: - DependencyKey

extension AuthClient: DependencyKey {
    static let liveValue: AuthClient = {
        let baseURL = URL(string: "https://api.birge.kz/api/v1")!

        let decoder: JSONDecoder = {
            let d = JSONDecoder()
            d.keyDecodingStrategy = .convertFromSnakeCase
            d.dateDecodingStrategy = .iso8601
            return d
        }()

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

                return try decoder.decode(JWT.self, from: data)
            }
        )
    }()

    static let testValue = AuthClient(
        requestOTP: { _ in
            try await Task.sleep(for: .milliseconds(500))
        },
        verifyOTP: { _, _ in
            try await Task.sleep(for: .milliseconds(500))
            return JWT(
                accessToken: "test-access-token",
                refreshToken: "test-refresh-token",
                expiresAt: Date().addingTimeInterval(3600)
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
