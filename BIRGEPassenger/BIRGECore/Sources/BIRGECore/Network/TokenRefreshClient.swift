//
//  TokenRefreshClient.swift
//  BIRGECore
//
//  Access-token memory store and refresh-token Keychain bridge.
//

import ComposableArchitecture
import Foundation
import Security

public struct TokenRefreshClient: Sendable {
    public var currentAccessToken: @Sendable () async throws -> String?
    public var storeTokens: @Sendable (_ accessToken: String, _ refreshToken: String) async throws -> Void
    public var refreshAccessToken: @Sendable () async throws -> String
    public var clearTokens: @Sendable () async throws -> Void

    public init(
        currentAccessToken: @escaping @Sendable () async throws -> String?,
        storeTokens: @escaping @Sendable (_ accessToken: String, _ refreshToken: String) async throws -> Void,
        refreshAccessToken: @escaping @Sendable () async throws -> String,
        clearTokens: @escaping @Sendable () async throws -> Void
    ) {
        self.currentAccessToken = currentAccessToken
        self.storeTokens = storeTokens
        self.refreshAccessToken = refreshAccessToken
        self.clearTokens = clearTokens
    }
}

extension TokenRefreshClient: DependencyKey {
    public static var liveValue: TokenRefreshClient {
        let transport = TokenRefreshTransport()
        return TokenRefreshClient(
            currentAccessToken: {
                await AccessTokenStore.shared.token
            },
            storeTokens: { accessToken, refreshToken in
                await AccessTokenStore.shared.setToken(accessToken)
                try KeychainCredentialStore.live.save(Self.refreshTokenKey, refreshToken)
            },
            refreshAccessToken: {
                try await transport.refreshAccessToken()
            },
            clearTokens: {
                await AccessTokenStore.shared.clear()
                try KeychainCredentialStore.live.delete(Self.refreshTokenKey)
                try KeychainCredentialStore.live.delete(Self.legacyAccessTokenKey)
                try KeychainCredentialStore.live.delete(Self.userIDKey)
            }
        )
    }

    public static var testValue: TokenRefreshClient {
        let accessToken = LockIsolated<String?>("test-access-token")
        let refreshToken = LockIsolated<String?>("test-refresh-token")
        return TokenRefreshClient(
            currentAccessToken: {
                accessToken.value
            },
            storeTokens: { newAccessToken, newRefreshToken in
                accessToken.withValue { $0 = newAccessToken }
                refreshToken.withValue { $0 = newRefreshToken }
            },
            refreshAccessToken: {
                guard refreshToken.value != nil else {
                    throw BIRGEAPIError.missingRefreshToken()
                }
                accessToken.withValue { $0 = "test-refreshed-access-token" }
                return "test-refreshed-access-token"
            },
            clearTokens: {
                accessToken.withValue { $0 = nil }
                refreshToken.withValue { $0 = nil }
            }
        )
    }
}

extension DependencyValues {
    public var tokenRefreshClient: TokenRefreshClient {
        get { self[TokenRefreshClient.self] }
        set { self[TokenRefreshClient.self] = newValue }
    }
}

private extension TokenRefreshClient {
    static let refreshTokenKey = "birge_refresh_token"
    static let legacyAccessTokenKey = "birge_access_token"
    static let userIDKey = "birge_user_id"
}

private actor AccessTokenStore {
    static let shared = AccessTokenStore()

    private var accessToken: String?

    var token: String? {
        accessToken
    }

    func setToken(_ token: String) {
        self.accessToken = token
    }

    func clear() {
        accessToken = nil
    }
}

private actor TokenRefreshTransport {
    private let encoder = JSONEncoder()
    private let decoder: JSONDecoder

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func refreshAccessToken() async throws -> String {
        guard let refreshToken = try KeychainCredentialStore.live.load(TokenRefreshClient.refreshTokenKey) else {
            throw BIRGEAPIError.missingRefreshToken()
        }

        var request = URLRequest(url: try refreshURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(RefreshTokenRequest(refreshToken: refreshToken))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BIRGEAPIError.invalidResponse()
        }

        guard (200...299).contains(http.statusCode) else {
            try? KeychainCredentialStore.live.delete(TokenRefreshClient.refreshTokenKey)
            await AccessTokenStore.shared.clear()
            if let apiError = try? decoder.decode(BIRGEAPIError.self, from: data) {
                throw apiError
            }
            throw BIRGEAPIError(
                errorCode: "HTTP_\(http.statusCode)",
                message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            )
        }

        let responseData = data.isEmpty ? Data("{}".utf8) : data
        let refreshResponse = try decoder.decode(RefreshTokenResponse.self, from: responseData)
        await AccessTokenStore.shared.setToken(refreshResponse.accessToken)
        if let rotatedRefreshToken = refreshResponse.refreshToken {
            try KeychainCredentialStore.live.save(TokenRefreshClient.refreshTokenKey, rotatedRefreshToken)
        }
        return refreshResponse.accessToken
    }

    private func refreshURL() throws -> URL {
        guard var url = URL(string: Self.baseURLString) else {
            throw BIRGEAPIError.invalidBaseURL()
        }
        url.appendPathComponent("auth")
        url.appendPathComponent("refresh")
        return url
    }

    private static var baseURLString: String {
        #if DEBUG
        "http://localhost:8080/api/v1"
        #else
        "https://api.birge.kz/api/v1"
        #endif
    }
}

private struct RefreshTokenRequest: Encodable {
    let refreshToken: String

    private enum CodingKeys: String, CodingKey {
        case refreshTokenCamel = "refreshToken"
        case refreshToken = "refresh_token"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(refreshToken, forKey: .refreshTokenCamel)
    }
}

private struct RefreshTokenResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case accessTokenSnake = "access_token"
        case refreshToken
        case refreshTokenSnake = "refresh_token"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decodeFlexibleString(.accessTokenSnake, .accessToken)
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshTokenSnake)
            ?? container.decodeIfPresent(String.self, forKey: .refreshToken)
    }
}

private struct KeychainCredentialStore: Sendable {
    var save: @Sendable (_ key: String, _ value: String) throws -> Void
    var load: @Sendable (_ key: String) throws -> String?
    var delete: @Sendable (_ key: String) throws -> Void

    static let live = KeychainCredentialStore(
        save: { key, value in
            guard let data = value.data(using: .utf8) else {
                throw BIRGEAPIError(errorCode: "KEYCHAIN_DATA_CONVERSION_FAILED", message: "Could not encode token.")
            }

            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
            ]
            SecItemDelete(deleteQuery as CFDictionary)

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ]

            let status = SecItemAdd(addQuery as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw BIRGEAPIError(errorCode: "KEYCHAIN_SAVE_FAILED", message: "Keychain save failed: \(status)")
            }
        },
        load: { key in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            guard status != errSecItemNotFound else { return nil }
            guard status == errSecSuccess else {
                throw BIRGEAPIError(errorCode: "KEYCHAIN_LOAD_FAILED", message: "Keychain load failed: \(status)")
            }
            guard let data = result as? Data,
                  let string = String(data: data, encoding: .utf8) else {
                throw BIRGEAPIError(errorCode: "KEYCHAIN_DATA_CONVERSION_FAILED", message: "Could not decode token.")
            }
            return string
        },
        delete: { key in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
            ]
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw BIRGEAPIError(errorCode: "KEYCHAIN_DELETE_FAILED", message: "Keychain delete failed: \(status)")
            }
        }
    )
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(_ keys: Key...) throws -> String {
        for key in keys {
            if let value = try decodeIfPresent(String.self, forKey: key) {
                return value
            }
        }
        throw DecodingError.keyNotFound(
            keys[0],
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected one of keys: \(keys.map(\.stringValue).joined(separator: ", "))"
            )
        )
    }
}
