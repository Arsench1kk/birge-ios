import BIRGECore
import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import BIRGEPassenger

@MainActor
final class SearchingFeatureTests: XCTestCase {
    func testOnAppearConnectsWithTokenizedRideURL() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: WebSocketEvent.self)
        let connectedURL = LockIsolated<URL?>(nil)
        let loadedKey = LockIsolated<String?>(nil)

        let store = TestStore(
            initialState: SearchingFeature.State(rideId: "ride-123")
        ) {
            SearchingFeature()
        } withDependencies: {
            $0.keychainClient = KeychainClient(
                save: { _, _ in },
                load: { key in
                    loadedKey.withValue { $0 = key }
                    return "test-token"
                },
                delete: { _ in }
            )
            $0.webSocketClient = WebSocketClient(
                connect: { url in
                    connectedURL.withValue { $0 = url }
                    return stream
                },
                send: { _ in },
                disconnect: {
                    continuation.finish()
                }
            )
        }

        await store.send(.view(.onAppear))
        try await waitUntil { connectedURL.value != nil }

        XCTAssertEqual(loadedKey.value, KeychainClient.Keys.accessToken)
        XCTAssertEqual(
            connectedURL.value?.absoluteString,
            "ws://localhost:8080/ws/ride/ride-123?token=test-token"
        )

        await store.send(.view(.onDisappear))
    }

    func testConnectedSendsRideSubscribeMessage() async throws {
        let sentMessages = LockIsolated<[WebSocketMessage]>([])

        let store = TestStore(
            initialState: SearchingFeature.State(rideId: "ride-123")
        ) {
            SearchingFeature()
        } withDependencies: {
            $0.webSocketClient = WebSocketClient(
                connect: { _ in AsyncStream { $0.finish() } },
                send: { message in
                    sentMessages.withValue { $0.append(message) }
                },
                disconnect: { }
            )
        }

        await store.send(.webSocketEventReceived(.connected))
        try await waitUntil { sentMessages.value.count == 1 }

        guard case let .text(text) = sentMessages.value.first else {
            XCTFail("Expected text subscribe message")
            return
        }
        let data = try XCTUnwrap(text.data(using: .utf8))
        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: String]
        )
        XCTAssertEqual(payload["type"], "subscribe")
        XCTAssertEqual(payload["channel"], "ride/ride-123")
        XCTAssertEqual(payload["ride_id"], "ride-123")
    }

    func testFlatRideMatchedEventDelegatesDriverInfo() async {
        let store = TestStore(
            initialState: SearchingFeature.State(rideId: "ride-123")
        ) {
            SearchingFeature()
        }

        let json = """
        {
          "event": "ride_matched",
          "driverId": "00000000-0000-0000-0000-000000000042",
          "driverName": "Асан Бекович",
          "driverRating": 4.9,
          "vehiclePlate": "777 ABA 02",
          "vehicleModel": "Chevrolet Nexia",
          "estimatedArrival": 4
        }
        """
        await store.send(.webSocketEventReceived(.message(.text(json))))
        await store.receive(\.delegate.rideMatched)
    }

    func testConnectionLossUpdatesSearchingState() async {
        let store = TestStore(
            initialState: SearchingFeature.State(rideId: "ride-123")
        ) {
            SearchingFeature()
        }

        await store.send(.webSocketEventReceived(.disconnected(.abnormalClosure, "lost"))) {
            $0.statusText = "Восстанавливаем соединение"
            $0.errorMessage = "Нет соединения. Пробуем переподключиться."
            $0.isConnectionLost = true
        }

        await store.send(.webSocketEventReceived(.error(.maxRetriesExceeded))) {
            $0.errorMessage = "Нет соединения."
        }
    }

    func testCancelTapCancelsRideAndDisconnects() async throws {
        let cancelCalled = LockIsolated(false)
        let disconnectCalled = LockIsolated(false)

        let store = TestStore(
            initialState: SearchingFeature.State(rideId: "ride-123")
        ) {
            SearchingFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                cancelRide: { rideID, reason in
                    XCTAssertEqual(rideID, "ride-123")
                    XCTAssertEqual(reason, "passenger_cancelled")
                    cancelCalled.withValue { $0 = true }
                }
            )
            $0.webSocketClient = WebSocketClient(
                connect: { _ in AsyncStream { $0.finish() } },
                send: { _ in },
                disconnect: {
                    disconnectCalled.withValue { $0 = true }
                }
            )
        }

        await store.send(.view(.cancelTapped)) {
            $0.isCancelling = true
            $0.errorMessage = nil
        }
        await store.receive(\.delegate.cancelled) {
            $0.isCancelling = false
        }
        try await waitUntil { disconnectCalled.value }

        XCTAssertTrue(cancelCalled.value)
    }

    private func waitUntil(
        timeout: Duration = .seconds(1),
        condition: @escaping @Sendable () -> Bool
    ) async throws {
        let start = ContinuousClock.now
        while !condition() {
            if ContinuousClock.now - start > timeout {
                XCTFail("Timed out waiting for condition")
                return
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}
