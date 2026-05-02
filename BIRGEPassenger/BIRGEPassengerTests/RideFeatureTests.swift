//
//  RideFeatureTests.swift
//  BIRGEPassengerTests
//
//  Unit tests for RideFeature TCA Reducer.
//  IOS-016 — RideFeature State Machine
//
//  Tests use TCA TestStore with mock dependencies.
//  No live backend required.
//

import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import BIRGECore
@testable import BIRGEPassenger

@MainActor
final class RideFeatureTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a JSON string for a RideEvent.
    private func makeEventJSON(
        event: String,
        rideId: String = "ride-123",
        payload: [String: Any],
        timestampMs: Int64 = 1_714_000_000_000
    ) -> String {
        let dict: [String: Any] = [
            "event": event,
            "ride_id": rideId,
            "timestamp_ms": timestampMs,
            "payload": payload
        ]
        let data = try! JSONSerialization.data(withJSONObject: dict)
        return String(data: data, encoding: .utf8)!
    }

    // MARK: - Test 1: Initial State Is Requested

    /// Confirms the default state starts with `.requested` status.
    func testInitialStateIsRequested() {
        let state = RideFeature.State(rideId: "ride-123")
        XCTAssertEqual(state.status, .requested)
        XCTAssertNil(state.driverLocation)
        XCTAssertNil(state.etaSeconds)
        XCTAssertNil(state.driverName)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.error)
    }

    // MARK: - Test 2: Status Transition Requested → Matched

    /// Confirms a `ride.status_changed` WebSocket event transitions
    /// the state from `.requested` to `.matched`.
    func testStatusTransitionRequestedToMatched() async throws {
        let store = TestStore(
            initialState: RideFeature.State(rideId: "ride-123")
        ) {
            RideFeature()
        }

        let json = makeEventJSON(
            event: RideEvent.EventType.statusChanged,
            payload: [
                "status": "matched",
                "driver_name": "Азамат К.",
                "driver_rating": 4.92
            ]
        )

        await store.send(.webSocketEventReceived(.message(.text(json)))) {
            $0.driverName = "Азамат К."
            $0.driverRating = 4.92
        }

        await store.receive(.rideStatusChanged(.matched)) {
            $0.status = .matched
        }
    }

    // MARK: - Test 3: Driver Location Updates State

    /// Confirms `ride.location_update` WebSocket event updates
    /// `state.driverLocation`.
    func testDriverLocationUpdatesState() async {
        let store = TestStore(
            initialState: RideFeature.State(
                rideId: "ride-123",
                status: .driverArriving
            )
        ) {
            RideFeature()
        }

        let json = makeEventJSON(
            event: RideEvent.EventType.locationUpdate,
            payload: [
                "lat": 43.2567,
                "lng": 76.9286
            ]
        )
        let expectedCoordinate = Coordinate(latitude: 43.2567, longitude: 76.9286)

        await store.send(.webSocketEventReceived(.message(.text(json))))

        await store.receive(.driverLocationUpdated(expectedCoordinate)) {
            $0.driverLocation = expectedCoordinate
        }
    }

    // MARK: - Test 4: ETA Updates On Interval

    /// Confirms `.etaUpdated` action updates `state.etaSeconds`.
    func testETAUpdatesOnInterval() async {
        let store = TestStore(
            initialState: RideFeature.State(
                rideId: "ride-123",
                status: .driverArriving,
                etaSeconds: 300
            )
        ) {
            RideFeature()
        }

        let json = makeEventJSON(
            event: RideEvent.EventType.etaUpdated,
            payload: [
                "eta_seconds": 180
            ]
        )

        await store.send(.webSocketEventReceived(.message(.text(json))))

        await store.receive(.etaUpdated(180)) {
            $0.etaSeconds = 180
        }
    }

    // MARK: - Test 5: Cancel Ride Dispatches Cancel Action

    /// Confirms `.cancelRideTapped` calls `apiClient.cancelRide`
    /// and transitions to `.cancelled` state.
    func testCancelRideDispatchesCancelAction() async {
        let cancelCalled = LockIsolated(false)

        let store = TestStore(
            initialState: RideFeature.State(
                rideId: "ride-123",
                status: .driverArriving
            )
        ) {
            RideFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                fetchRide: { _ in RideResponse(rideId: "ride-123", status: "requested") },
                cancelRide: { _, _ in cancelCalled.withValue { $0 = true } }
            )
        }

        await store.send(.view(.cancelRideTapped(reason: "Changed mind"))) {
            $0.isLoading = true
            $0.cancellationReason = "Changed mind"
        }

        await store.receive(.cancelConfirmed) {
            $0.isLoading = false
            $0.status = .cancelled
        }

        await store.receive(.delegate(.cancelled))

        XCTAssertTrue(cancelCalled.value, "apiClient.cancelRide should have been called")
    }

    // MARK: - Test 6: WebSocket Reconnect Fetches Ride

    /// Confirms that `.webSocketConnected` triggers a fetch from the
    /// server to recover any missed state transitions.
    func testWebSocketReconnectFetchesRide() async {
        let fetchCalled = LockIsolated(false)

        let store = TestStore(
            initialState: RideFeature.State(
                rideId: "ride-123",
                status: .driverArriving
            )
        ) {
            RideFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                fetchRide: { _ in
                    fetchCalled.withValue { $0 = true }
                    return RideResponse(
                        rideId: "ride-123",
                        status: "driver_arriving",
                        etaSeconds: 120
                    )
                },
                cancelRide: { _, _ in }
            )
        }

        // Simulate reconnect
        await store.send(.webSocketConnected)

        // Should fetch ride from server
        await store.receive(.rideLoadedFromServer(
            RideResponse(rideId: "ride-123", status: "driver_arriving", etaSeconds: 120)
        )) {
            $0.etaSeconds = 120
        }

        XCTAssertTrue(fetchCalled.value, "apiClient.fetchRide should have been called on reconnect")
    }

    // MARK: - Test 7: WebSocket Disconnect Recovers Ride State

    /// Confirms that `.webSocketDisconnected` also fetches server state
    /// so the reducer can recover transitions missed during a dropped socket.
    func testWebSocketDisconnectFetchesRide() async {
        let fetchCalled = LockIsolated(false)

        let store = TestStore(
            initialState: RideFeature.State(
                rideId: "ride-123",
                status: .driverArriving
            )
        ) {
            RideFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                fetchRide: { _ in
                    fetchCalled.withValue { $0 = true }
                    return RideResponse(
                        rideId: "ride-123",
                        status: "passenger_wait",
                        verificationCode: "1234"
                    )
                },
                cancelRide: { _, _ in }
            )
        }

        await store.send(.webSocketDisconnected)

        await store.receive(.rideLoadedFromServer(
            RideResponse(
                rideId: "ride-123",
                status: "passenger_wait",
                verificationCode: "1234"
            )
        )) {
            $0.verificationCode = "1234"
        }

        await store.receive(.rideStatusChanged(.passengerWait)) {
            $0.status = .passengerWait
            $0.waitCountdownSeconds = 180
        }

        XCTAssertTrue(fetchCalled.value, "apiClient.fetchRide should have been called on disconnect")

        await store.send(.view(.onDisappear))
    }
}
