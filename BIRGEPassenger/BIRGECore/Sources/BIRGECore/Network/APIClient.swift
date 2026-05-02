//
//  APIClient.swift
//  BIRGECore
//
//  URLSession-backed Phase 1 API client.
//

import ComposableArchitecture
import Foundation
import Security

// MARK: - API Error

public struct BIRGEAPIError: Error, Decodable, Equatable, Sendable, LocalizedError {
    public let errorCode: String
    public let message: String
    public let requestID: String?

    public var errorDescription: String? {
        message.isEmpty ? errorCode : message
    }

    public init(errorCode: String, message: String, requestID: String? = nil) {
        self.errorCode = errorCode
        self.message = message
        self.requestID = requestID
    }

    private enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case message
        case requestID = "request_id"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.errorCode = try container.decode(String.self, forKey: .errorCode)
        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? errorCode
        self.requestID = try container.decodeIfPresent(String.self, forKey: .requestID)
    }

    static func invalidBaseURL() -> BIRGEAPIError {
        BIRGEAPIError(errorCode: "INVALID_BASE_URL", message: "Invalid API base URL.")
    }

    static func invalidResponse() -> BIRGEAPIError {
        BIRGEAPIError(errorCode: "INVALID_RESPONSE", message: "Invalid server response.")
    }

    static func missingAccessToken() -> BIRGEAPIError {
        BIRGEAPIError(errorCode: "MISSING_ACCESS_TOKEN", message: "No access token is available.")
    }

    static func missingRefreshToken() -> BIRGEAPIError {
        BIRGEAPIError(errorCode: "MISSING_REFRESH_TOKEN", message: "No refresh token is available.")
    }
}

// MARK: - Shared DTOs

public struct LatLng: Codable, Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case lat
        case lng
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let latitude = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            self.latitude = latitude
            self.longitude = longitude
        } else {
            self.latitude = try container.decode(Double.self, forKey: .lat)
            self.longitude = try container.decode(Double.self, forKey: .lng)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(latitude, forKey: .lat)
        try container.encode(longitude, forKey: .lng)
    }
}

public struct APIAuthResponse: Equatable, Sendable, Decodable {
    public let accessToken: String
    public let refreshToken: String
    public let role: String
    public let userID: String

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case userID
        case accessTokenSnake = "access_token"
        case refreshTokenSnake = "refresh_token"
        case userIDSnake = "user_id"
        case role
    }

    public init(accessToken: String, refreshToken: String, role: String, userID: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.role = role
        self.userID = userID
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decodeFlexibleString(.accessTokenSnake, .accessToken)
        self.refreshToken = try container.decodeFlexibleString(.refreshTokenSnake, .refreshToken)
        self.userID = try container.decodeFlexibleString(.userIDSnake, .userID)
        self.role = try container.decode(String.self, forKey: .role)
    }
}

public struct CurrentUserResponse: Equatable, Sendable, Decodable {
    public let id: String
    public let phone: String
    public let email: String?
    public let role: String
    public let name: String?
    public let rating: Double?
    public let totalRides: Int?
    public let createdAt: Date?

    public init(
        id: String,
        phone: String,
        email: String? = nil,
        role: String,
        name: String? = nil,
        rating: Double? = nil,
        totalRides: Int? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.phone = phone
        self.email = email
        self.role = role
        self.name = name
        self.rating = rating
        self.totalRides = totalRides
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case phone
        case email
        case role
        case name
        case rating
        case totalRides
        case totalRidesSnake = "total_rides"
        case createdAt
        case createdAtSnake = "created_at"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.phone = try container.decode(String.self, forKey: .phone)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.role = try container.decode(String.self, forKey: .role)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        self.totalRides = try container.decodeIfPresent(Int.self, forKey: .totalRidesSnake)
            ?? container.decodeIfPresent(Int.self, forKey: .totalRides)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAtSnake)
            ?? container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
}

public struct LocationBulkResponse: Equatable, Sendable, Decodable {
    public let message: String?
    public let count: Int?

    public init(message: String? = nil, count: Int? = nil) {
        self.message = message
        self.count = count
    }
}

private struct CancelRideRequest: Encodable {
    let reason: String
}

private struct OTPRequest: Encodable {
    let phone: String
}

private struct OTPVerifyRequest: Encodable {
    let phone: String
    let code: String
}

private struct LocationBulkRequest: Encodable {
    let rideID: String
    let records: [LocationRecordRequest]

    private enum CodingKeys: String, CodingKey {
        case rideID = "ride_id"
        case records
    }
}

private struct LocationRecordRequest: Encodable {
    let latitude: Double
    let longitude: Double
    let timestamp: Double
    let accuracy: Double?

    init(_ record: LocationRecord) {
        self.latitude = record.latitude
        self.longitude = record.longitude
        self.timestamp = record.timestamp
        self.accuracy = record.accuracy
    }
}

// MARK: - API Client

public struct APIClient: Sendable {
    public var requestOTP: @Sendable (_ phone: String) async throws -> Void
    public var verifyOTP: @Sendable (_ phone: String, _ code: String) async throws -> APIAuthResponse
    public var refreshAccessToken: @Sendable () async throws -> String
    public var currentUser: @Sendable () async throws -> CurrentUserResponse
    public var createRide: @Sendable (_ request: CreateRideRequest) async throws -> RideDTO
    public var fetchRide: @Sendable (_ rideID: String) async throws -> RideDTO
    public var cancelRide: @Sendable (_ rideID: String, _ reason: String) async throws -> Void
    public var uploadLocationsBulk: @Sendable (_ rideID: String, _ records: [LocationRecord]) async throws -> LocationBulkResponse

    public init(
        fetchRide: @escaping @Sendable (_ rideID: String) async throws -> RideDTO = { _ in
            RideDTO(status: "requested")
        },
        cancelRide: @escaping @Sendable (_ rideID: String, _ reason: String) async throws -> Void = { _, _ in },
        requestOTP: @escaping @Sendable (_ phone: String) async throws -> Void = { _ in },
        verifyOTP: @escaping @Sendable (_ phone: String, _ code: String) async throws -> APIAuthResponse = { _, _ in
            APIAuthResponse(accessToken: "test-access-token", refreshToken: "test-refresh-token", role: "passenger", userID: "test-user-id")
        },
        refreshAccessToken: @escaping @Sendable () async throws -> String = { "test-access-token" },
        currentUser: @escaping @Sendable () async throws -> CurrentUserResponse = {
            CurrentUserResponse(id: "test-user-id", phone: "+77771234567", role: "passenger")
        },
        createRide: @escaping @Sendable (_ request: CreateRideRequest) async throws -> RideDTO = { _ in
            RideDTO(status: "requested")
        },
        uploadLocationsBulk: @escaping @Sendable (_ rideID: String, _ records: [LocationRecord]) async throws -> LocationBulkResponse = { _, records in
            LocationBulkResponse(message: "Locations synced", count: records.count)
        }
    ) {
        self.requestOTP = requestOTP
        self.verifyOTP = verifyOTP
        self.refreshAccessToken = refreshAccessToken
        self.currentUser = currentUser
        self.createRide = createRide
        self.fetchRide = fetchRide
        self.cancelRide = cancelRide
        self.uploadLocationsBulk = uploadLocationsBulk
    }
}

// MARK: - DependencyKey

extension APIClient: DependencyKey {
    public static var liveValue: APIClient {
        let tokenRefreshClient = TokenRefreshClient.liveValue
        let transport = LiveAPITransport(tokenRefreshClient: tokenRefreshClient)
        return APIClient(
            fetchRide: { rideID in
                try await transport.sendAuthenticated(
                    path: ["rides", rideID],
                    method: "GET",
                    responseType: RideResponse.self
                )
            },
            cancelRide: { rideID, reason in
                let _: EmptyResponse = try await transport.sendAuthenticated(
                    path: ["rides", rideID, "cancel"],
                    method: "PUT",
                    body: CancelRideRequest(reason: reason),
                    responseType: EmptyResponse.self
                )
            },
            requestOTP: { phone in
                let _: EmptyResponse = try await transport.sendUnauthenticated(
                    path: ["auth", "otp", "request"],
                    method: "POST",
                    body: OTPRequest(phone: phone),
                    responseType: EmptyResponse.self
                )
            },
            verifyOTP: { phone, code in
                let response: APIAuthResponse = try await transport.sendUnauthenticated(
                    path: ["auth", "otp", "verify"],
                    method: "POST",
                    body: OTPVerifyRequest(phone: phone, code: code),
                    responseType: APIAuthResponse.self
                )
                try await tokenRefreshClient.storeTokens(
                    response.accessToken,
                    response.refreshToken
                )
                return response
            },
            refreshAccessToken: {
                try await tokenRefreshClient.refreshAccessToken()
            },
            currentUser: {
                try await transport.sendAuthenticated(
                    path: ["auth", "me"],
                    method: "GET",
                    responseType: CurrentUserResponse.self
                )
            },
            createRide: { request in
                try await transport.sendAuthenticated(
                    path: ["rides"],
                    method: "POST",
                    body: request,
                    responseType: RideDTO.self
                )
            },
            uploadLocationsBulk: { rideID, records in
                try await transport.sendAuthenticated(
                    path: ["locations", "bulk"],
                    method: "POST",
                    body: LocationBulkRequest(
                        rideID: rideID,
                        records: records.map(LocationRecordRequest.init)
                    ),
                    responseType: LocationBulkResponse.self
                )
            }
        )
    }

    public static var testValue: APIClient {
        APIClient()
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

// MARK: - Live Transport

private actor LiveAPITransport {
    private let tokenRefreshClient: TokenRefreshClient
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(tokenRefreshClient: TokenRefreshClient) {
        self.tokenRefreshClient = tokenRefreshClient
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func sendUnauthenticated<Response: Decodable & Sendable>(
        path: [String],
        method: String,
        responseType: Response.Type
    ) async throws -> Response {
        try await send(path: path, method: method, bodyData: nil, bearerToken: nil, responseType: responseType)
    }

    func sendUnauthenticated<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        path: [String],
        method: String,
        body: Body,
        responseType: Response.Type
    ) async throws -> Response {
        let bodyData = try encoder.encode(body)
        return try await send(path: path, method: method, bodyData: bodyData, bearerToken: nil, responseType: responseType)
    }

    func sendAuthenticated<Response: Decodable & Sendable>(
        path: [String],
        method: String,
        responseType: Response.Type
    ) async throws -> Response {
        try await sendAuthenticated(path: path, method: method, bodyData: nil, responseType: responseType)
    }

    func sendAuthenticated<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        path: [String],
        method: String,
        body: Body,
        responseType: Response.Type
    ) async throws -> Response {
        let bodyData = try encoder.encode(body)
        return try await sendAuthenticated(path: path, method: method, bodyData: bodyData, responseType: responseType)
    }

    private func sendAuthenticated<Response: Decodable & Sendable>(
        path: [String],
        method: String,
        bodyData: Data?,
        responseType: Response.Type
    ) async throws -> Response {
        let accessToken = try await accessTokenForRequest()
        do {
            return try await send(path: path, method: method, bodyData: bodyData, bearerToken: accessToken, responseType: responseType)
        } catch let error as HTTPStatusError where error.statusCode == 401 {
            let refreshedToken = try await tokenRefreshClient.refreshAccessToken()
            do {
                return try await send(path: path, method: method, bodyData: bodyData, bearerToken: refreshedToken, responseType: responseType)
            } catch let retryError as HTTPStatusError where retryError.statusCode == 401 {
                try? await tokenRefreshClient.clearTokens()
                throw BIRGEAPIError(errorCode: "UNAUTHORIZED", message: "Authentication expired.")
            }
        }
    }

    private func accessTokenForRequest() async throws -> String {
        if let token = try await tokenRefreshClient.currentAccessToken() {
            return token
        }
        if let token = try KeychainCredentialStore.live.load(TokenRefreshClient.legacyAccessTokenKey) {
            await AccessTokenStore.shared.setToken(token)
            return token
        }
        return try await tokenRefreshClient.refreshAccessToken()
    }

    private func send<Response: Decodable & Sendable>(
        path: [String],
        method: String,
        bodyData: Data?,
        bearerToken: String?,
        responseType: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: try url(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bodyData {
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BIRGEAPIError.invalidResponse()
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw HTTPStatusError(statusCode: http.statusCode)
            }
            throw decodeAPIError(from: data, statusCode: http.statusCode)
        }

        let responseData = data.isEmpty ? Data("{}".utf8) : data
        return try decoder.decode(Response.self, from: responseData)
    }

    private func decodeAPIError(from data: Data, statusCode: Int) -> BIRGEAPIError {
        if let error = try? decoder.decode(BIRGEAPIError.self, from: data) {
            return error
        }
        return BIRGEAPIError(
            errorCode: "HTTP_\(statusCode)",
            message: HTTPURLResponse.localizedString(forStatusCode: statusCode)
        )
    }

    private func url(path: [String]) throws -> URL {
        guard var url = URL(string: Self.baseURLString) else {
            throw BIRGEAPIError.invalidBaseURL()
        }
        for component in path {
            url.appendPathComponent(component)
        }
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

private struct EmptyResponse: Decodable, Sendable {
    init() {}

    init(from decoder: any Decoder) throws {
        self.init()
    }
}

private struct HTTPStatusError: Error, Sendable {
    let statusCode: Int
}

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
