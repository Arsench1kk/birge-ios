import BIRGECore
import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import BIRGEPassenger

@MainActor
final class ProfileFeatureTests: XCTestCase {
    func testLogoutRevokesSessionBeforeClearingCredentials() async {
        let steps = LockIsolated<[String]>([])
        let store = TestStore(initialState: ProfileFeature.State()) { ProfileFeature() } withDependencies: {
            $0.tokenRefreshClient.revokeSession = { steps.withValue { $0.append("revoke") } }
            $0.tokenRefreshClient.clearTokens = { steps.withValue { $0.append("clear") } }
        }
        await store.send(.logoutTapped)
        await store.receive(\.delegate.loggedOut)
        XCTAssertEqual(steps.value, ["revoke", "clear"])
    }

    func testLogoutFailureKeepsCredentialsForRetry() async {
        let cleared = LockIsolated(false)
        let store = TestStore(initialState: ProfileFeature.State()) { ProfileFeature() } withDependencies: {
            $0.tokenRefreshClient.revokeSession = { throw BIRGEAPIError(errorCode: "NETWORK", message: "offline") }
            $0.tokenRefreshClient.clearTokens = { cleared.withValue { $0 = true } }
        }
        await store.send(.logoutTapped)
        await store.receive(\.logoutFailed) {
            $0.isLogoutError = true
            $0.errorMessage = "Проверьте подключение и попробуйте ещё раз."
        }
        XCTAssertFalse(cleared.value)
    }

    func testOnAppearFetchesProfileAndStoresRealValues() async {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        let fetchCalled = LockIsolated(false)

        let store = TestStore(initialState: ProfileFeature.State()) {
            ProfileFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                fetchMe: {
                    fetchCalled.withValue { $0 = true }
                    return UserDTO(
                        id: userID,
                        phone: "+77771234567",
                        name: "Арсен",
                        rating: 4.8,
                        totalRides: 12,
                        createdAt: Date(timeIntervalSince1970: 1_735_689_600)
                    )
                }
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.profileLoaded) {
            $0.isLoading = false
            $0.errorMessage = nil
            $0.name = "Арсен"
            $0.phone = "+77771234567"
            $0.rating = 4.8
            $0.totalRides = 12
        }

        XCTAssertTrue(fetchCalled.value)
    }

    func testOnAppearFailureShowsRetryState() async {
        let store = TestStore(initialState: ProfileFeature.State()) {
            ProfileFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                fetchMe: {
                    throw BIRGEAPIError(errorCode: "NETWORK", message: "Network unavailable")
                }
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.profileLoadFailed) {
            $0.isLoading = false
            $0.errorMessage = "Network unavailable"
        }
    }

    func testUnauthorizedFailureLogsOut() async {
        let store = TestStore(initialState: ProfileFeature.State()) {
            ProfileFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                fetchMe: {
                    throw BIRGEAPIError(errorCode: "UNAUTHORIZED", message: "Authentication expired.")
                }
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.profileUnauthorized) {
            $0.isLoading = false
            $0.errorMessage = nil
        }

        await store.receive(\.delegate.loggedOut)
    }
}
