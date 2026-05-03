import ConcurrencyExtras
import XCTest
@testable import BIRGECore

final class APIClientRefreshTests: XCTestCase {
    func testAuthenticatedRequestRefreshesAndRetriesAfter401() async throws {
        let storage = LockIsolated([
            TokenCredentialStore.accessTokenKey: "expired-access",
            TokenCredentialStore.refreshTokenKey: "refresh-token",
        ])
        let requestPaths = LockIsolated<[String]>([])
        let authHeaders = LockIsolated<[String?]>([])

        let client = APIClient.makeLive(
            baseURLString: "https://example.com/api/v1",
            credentialStore: Self.credentialStore(storage),
            authSessionClient: Self.authSessionClient(),
            sendRequest: { request in
                requestPaths.withValue { $0.append(request.url?.path ?? "") }
                authHeaders.withValue { $0.append(request.value(forHTTPHeaderField: "Authorization")) }

                switch request.url?.path {
                case "/api/v1/auth/me":
                    if request.value(forHTTPHeaderField: "Authorization") == "Bearer expired-access" {
                        return (Data(), Self.response(for: request, status: 401))
                    }
                    return (Self.userData, Self.response(for: request, status: 200))

                case "/api/v1/auth/refresh":
                    return (
                        Data(#"{"accessToken":"new-access","refreshToken":"new-refresh"}"#.utf8),
                        Self.response(for: request, status: 200)
                    )

                default:
                    return (Data(), Self.response(for: request, status: 404))
                }
            }
        )

        let user = try await client.fetchMe()

        XCTAssertEqual(user.phone, "+77771234567")
        XCTAssertEqual(requestPaths.value, [
            "/api/v1/auth/me",
            "/api/v1/auth/refresh",
            "/api/v1/auth/me",
        ])
        XCTAssertEqual(authHeaders.value[0], "Bearer expired-access")
        XCTAssertNil(authHeaders.value[1])
        XCTAssertEqual(authHeaders.value[2], "Bearer new-access")
        XCTAssertEqual(storage.value[TokenCredentialStore.accessTokenKey], "new-access")
        XCTAssertEqual(storage.value[TokenCredentialStore.refreshTokenKey], "new-refresh")
    }

    func testRefreshFailureEmitsAuthExpiredAndClearsTokens() async {
        let storage = LockIsolated([
            TokenCredentialStore.accessTokenKey: "expired-access",
            TokenCredentialStore.refreshTokenKey: "refresh-token",
            TokenCredentialStore.userIDKey: "user-id",
        ])
        let expiredMessages = LockIsolated<[String]>([])

        let client = APIClient.makeLive(
            baseURLString: "https://example.com/api/v1",
            credentialStore: Self.credentialStore(storage),
            authSessionClient: Self.authSessionClient(expiredMessages: expiredMessages),
            sendRequest: { request in
                switch request.url?.path {
                case "/api/v1/auth/me":
                    return (Data(), Self.response(for: request, status: 401))

                case "/api/v1/auth/refresh":
                    return (Data(), Self.response(for: request, status: 401))

                default:
                    return (Data(), Self.response(for: request, status: 404))
                }
            }
        )

        do {
            _ = try await client.fetchMe()
            XCTFail("Expected fetchMe to throw after refresh failure.")
        } catch let error as BIRGEAPIError {
            XCTAssertEqual(error.errorCode, "UNAUTHORIZED")
        } catch {
            XCTFail("Expected BIRGEAPIError, got \(error).")
        }

        XCTAssertNil(storage.value[TokenCredentialStore.accessTokenKey])
        XCTAssertNil(storage.value[TokenCredentialStore.refreshTokenKey])
        XCTAssertNil(storage.value[TokenCredentialStore.userIDKey])
        XCTAssertEqual(expiredMessages.value, ["Сессия истекла. Войдите снова."])
    }

    func testConcurrent401sShareOneRefreshCall() async throws {
        let storage = LockIsolated([
            TokenCredentialStore.accessTokenKey: "expired-access",
            TokenCredentialStore.refreshTokenKey: "refresh-token",
        ])
        let refreshCalls = LockIsolated(0)

        let client = APIClient.makeLive(
            baseURLString: "https://example.com/api/v1",
            credentialStore: Self.credentialStore(storage),
            authSessionClient: Self.authSessionClient(),
            sendRequest: { request in
                switch request.url?.path {
                case "/api/v1/auth/me":
                    if request.value(forHTTPHeaderField: "Authorization") == "Bearer expired-access" {
                        return (Data(), Self.response(for: request, status: 401))
                    }
                    return (Self.userData, Self.response(for: request, status: 200))

                case "/api/v1/auth/refresh":
                    refreshCalls.withValue { $0 += 1 }
                    try await Task.sleep(for: .milliseconds(100))
                    return (
                        Data(#"{"accessToken":"new-access","refreshToken":"new-refresh"}"#.utf8),
                        Self.response(for: request, status: 200)
                    )

                default:
                    return (Data(), Self.response(for: request, status: 404))
                }
            }
        )

        async let first = client.fetchMe()
        async let second = client.fetchMe()
        let users = try await [first, second]

        XCTAssertEqual(users.map(\.phone), ["+77771234567", "+77771234567"])
        XCTAssertEqual(refreshCalls.value, 1)
        XCTAssertEqual(storage.value[TokenCredentialStore.accessTokenKey], "new-access")
        XCTAssertEqual(storage.value[TokenCredentialStore.refreshTokenKey], "new-refresh")
    }

    private static func credentialStore(
        _ storage: LockIsolated<[String: String]>
    ) -> TokenCredentialStore {
        TokenCredentialStore(
            save: { key, value in
                storage.withValue { $0[key] = value }
            },
            load: { key in
                storage.value[key]
            },
            delete: { key in
                storage.withValue { $0[key] = nil }
            }
        )
    }

    private static func authSessionClient(
        expiredMessages: LockIsolated<[String]> = LockIsolated([])
    ) -> AuthSessionClient {
        AuthSessionClient(
            events: {
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            sendAuthExpired: { message in
                expiredMessages.withValue { $0.append(message) }
            }
        )
    }

    private static func response(for request: URLRequest, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: status,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private static let userData = Data(
        """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "phone": "+77771234567",
          "name": "Test User",
          "rating": 0.0,
          "totalRides": 0,
          "createdAt": "2026-05-03T00:00:00Z"
        }
        """.utf8
    )
}
