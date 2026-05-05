import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class AppFeatureNavigationTests: XCTestCase {
    func testSplashRoutesToNeedsOnboardingWhenTokenIsMissing() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.keychainClient.load = { _ in nil }
        }

        await store.send(.splash(.delegate(.splashFinished))) {
            $0 = .needsOnboarding(OnboardingFeature.State())
        }
    }

    func testOnboardingCompletionRoutesToOTP() async {
        let store = TestStore(
            initialState: AppFeature.State.needsOnboarding(OnboardingFeature.State())
        ) {
            AppFeature()
        }

        await store.send(.onboarding(.delegate(.onboardingFinished))) {
            $0 = .unauthenticated(OTPFeature.State())
        }
    }

    func testLogoutClearsSessionAndReturnsToOTP() async {
        let deletedKeys = LockIsolated<[String]>([])

        let store = TestStore(
            initialState: AppFeature.State.authenticated(PassengerAppFeature.State())
        ) {
            AppFeature()
        } withDependencies: {
            $0.keychainClient.delete = { key in
                deletedKeys.withValue { $0.append(key) }
            }
        }

        await store.send(.passengerApp(.delegate(.loggedOut))) {
            $0 = .unauthenticated(OTPFeature.State())
        }

        XCTAssertEqual(deletedKeys.value, [
            "birge_access_token",
            "birge_refresh_token",
            "birge_user_id"
        ])
    }
}
