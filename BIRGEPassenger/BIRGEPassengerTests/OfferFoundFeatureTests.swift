import BIRGECore
import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import BIRGEPassenger

@MainActor
final class OfferFoundFeatureTests: XCTestCase {
    func testDeclineCancelsAcceptedRideBeforeNavigatingHome() async {
        let calls = LockIsolated<[(String, String)]>([])

        let store = TestStore(initialState: offerState(secondsRemaining: 30)) {
            OfferFoundFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                cancelRide: { rideID, reason in
                    calls.withValue { $0.append((rideID, reason)) }
                }
            )
        }

        await store.send(.view(.declineTapped)) {
            $0.isConfirming = true
            $0.errorMessage = nil
        }

        await store.receive(\.declineCancelSucceeded) {
            $0.isConfirming = false
            $0.errorMessage = nil
        }

        await store.receive(\.delegate.declined)

        XCTAssertEqual(calls.value.count, 1)
        XCTAssertEqual(calls.value.first?.0, "ride-123")
        XCTAssertEqual(calls.value.first?.1, "passenger_declined_offer")
    }

    func testExpiryCancelsAcceptedRideBeforeNavigatingHome() async {
        let calls = LockIsolated<[(String, String)]>([])

        let store = TestStore(initialState: offerState(secondsRemaining: 1)) {
            OfferFoundFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                cancelRide: { rideID, reason in
                    calls.withValue { $0.append((rideID, reason)) }
                }
            )
        }

        await store.send(.countdownTicked) {
            $0.secondsRemaining = 0
            $0.isConfirming = true
            $0.errorMessage = nil
        }

        await store.receive(\.expiryCancelSucceeded) {
            $0.isConfirming = false
            $0.errorMessage = nil
        }

        await store.receive(\.delegate.expired)

        XCTAssertEqual(calls.value.count, 1)
        XCTAssertEqual(calls.value.first?.0, "ride-123")
        XCTAssertEqual(calls.value.first?.1, "offer_expired")
    }

    private func offerState(secondsRemaining: Int) -> OfferFoundFeature.State {
        var state = OfferFoundFeature.State(
            rideId: "ride-123",
            driverInfo: SearchingFeature.DriverInfo(
                driverId: "driver-123",
                driverName: "Асан Бекович",
                driverRating: 4.9,
                driverVehicle: "Toyota Camry",
                driverPlate: "777 ABA 02",
                etaSeconds: 240
            )
        )
        state.secondsRemaining = secondsRemaining
        return state
    }
}
