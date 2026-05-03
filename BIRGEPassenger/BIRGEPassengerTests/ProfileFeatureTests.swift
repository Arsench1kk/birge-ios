import BIRGECore
import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import BIRGEPassenger

@MainActor
final class ProfileFeatureTests: XCTestCase {
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
