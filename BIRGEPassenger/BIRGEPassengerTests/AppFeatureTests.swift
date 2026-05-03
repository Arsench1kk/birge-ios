import BIRGECore
import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import BIRGEPassenger

@MainActor
final class AppFeatureTests: XCTestCase {
    func testAuthExpiredClearsTokensAndReturnsToOTP() async {
        let deletedKeys = LockIsolated<[String]>([])
        let message = "Сессия истекла. Войдите снова."

        let store = TestStore(initialState: AppFeature.State.authenticated(PassengerAppFeature.State())) {
            AppFeature()
        } withDependencies: {
            $0.keychainClient.delete = { key in
                deletedKeys.withValue { $0.append(key) }
            }
        }

        await store.send(.authSessionEventReceived(.authExpired(message: message))) {
            var otpState = OTPFeature.State()
            otpState.errorMessage = message
            $0 = .unauthenticated(otpState)
        }

        XCTAssertEqual(
            Set(deletedKeys.value),
            Set([
                KeychainClient.Keys.accessToken,
                KeychainClient.Keys.refreshToken,
                KeychainClient.Keys.userID
            ])
        )
    }
}
