//
//  WebSocketClientTests.swift
//  BIRGEPassengerTests
//
//  Unit tests for WebSocketClient TCA Dependency.
//  IOS-014 — WebSocketClient TCA Dependency
//
//  Tests use the `testValue` mock with controllable AsyncStream.
//  The mock is designed for downstream reducer tests (IOS-016 RideFeature).
//

import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import BIRGECore

@MainActor
final class WebSocketClientTests: XCTestCase {

    // MARK: - Helpers

    /// Safe URL construction — avoids force unwrap in tests.
    private var testURL: URL {
        get throws {
            guard let url = URL(string: "wss://test.birge.kz/ws") else {
                throw URLError(.badURL)
            }
            return url
        }
    }

    /// Creates a test client with all controllable parts exposed.
    private func makeTestClient() -> (
        client: WebSocketClient,
        continuation: AsyncStream<WebSocketEvent>.Continuation,
        sentMessages: LockIsolated<[WebSocketMessage]>,
        disconnectCalled: LockIsolated<Bool>
    ) {
        let (stream, continuation) = AsyncStream.makeStream(of: WebSocketEvent.self)
        let sentMessages = LockIsolated<[WebSocketMessage]>([])
        let disconnectCalled = LockIsolated(false)

        let client = WebSocketClient.test(
            events: stream,
            continuation: continuation,
            sentMessages: sentMessages,
            disconnectCalled: disconnectCalled
        )

        return (client, continuation, sentMessages, disconnectCalled)
    }

    // MARK: - testConnectYieldsConnectedEvent

    /// Confirms `.connected` is the first event yielded after `connect()`.
    func testConnectYieldsConnectedEvent() async throws {
        let (client, continuation, _, _) = makeTestClient()

        // Push .connected via the continuation
        continuation.yield(.connected)

        // Connect and read the first event
        let eventStream = await client.connect(try testURL)
        var iterator = eventStream.makeAsyncIterator()
        let firstEvent = await iterator.next()

        // Assert it is .connected
        guard case .connected = firstEvent else {
            XCTFail("Expected .connected as first event, got \(String(describing: firstEvent))")
            return
        }

        continuation.finish()
    }

    // MARK: - testSendMessage

    /// Confirms a sent `.text` message is captured by the mock.
    func testSendMessage() async throws {
        let (client, continuation, sentMessages, _) = makeTestClient()

        // Send a text message
        try await client.send(.text("hello"))

        // Assert it was captured
        sentMessages.withValue { messages in
            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages.first, .text("hello"))
        }

        // Send a data message
        let testData = Data("binary".utf8)
        try await client.send(.data(testData))

        sentMessages.withValue { messages in
            XCTAssertEqual(messages.count, 2)
            XCTAssertEqual(messages.last, .data(testData))
        }

        continuation.finish()
    }

    // MARK: - testDisconnectCancelsStream

    /// Confirms that calling `disconnect()` finishes the stream
    /// and the stream terminates cleanly without hanging.
    func testDisconnectCancelsStream() async throws {
        let (client, continuation, _, disconnectCalled) = makeTestClient()

        // Connect
        let eventStream = await client.connect(try testURL)

        // Yield one event so the stream has started
        continuation.yield(.connected)

        // Disconnect — this should finish the continuation
        await client.disconnect()

        // Assert disconnect was called
        disconnectCalled.withValue { called in
            XCTAssertTrue(called, "disconnect() should set disconnectCalled to true")
        }

        // Consume the stream — it should terminate (not hang)
        var events: [WebSocketEvent] = []
        for await event in eventStream {
            events.append(event)
        }

        // Stream should have terminated after disconnect
        // We expect at most the .connected event that was yielded before disconnect
        XCTAssertTrue(events.count <= 1, "Stream should terminate after disconnect")
    }

    // MARK: - testMessageRoundTrip

    /// Confirms that a message event yielded via the continuation
    /// is received by the consumer of the connect stream.
    func testMessageRoundTrip() async throws {
        let (client, continuation, _, _) = makeTestClient()

        // Push events then finish
        continuation.yield(.connected)
        continuation.yield(.message(.text("{\"event\":\"ride_matched\"}")))
        continuation.finish()

        // Consume the stream
        let eventStream = await client.connect(try testURL)
        var receivedEvents: [WebSocketEvent] = []
        for await event in eventStream {
            receivedEvents.append(event)
        }

        // Assert we got both events
        XCTAssertEqual(receivedEvents.count, 2)

        guard case .connected = receivedEvents[0] else {
            XCTFail("First event should be .connected")
            return
        }

        guard case .message(.text(let text)) = receivedEvents[1] else {
            XCTFail("Second event should be .message(.text(...))")
            return
        }
        XCTAssertEqual(text, "{\"event\":\"ride_matched\"}")
    }

    // MARK: - testMultipleSendsCaptured

    /// Confirms that multiple sent messages are captured in order.
    func testMultipleSendsCaptured() async throws {
        let (client, continuation, sentMessages, _) = makeTestClient()

        // Send multiple messages
        try await client.send(.text("msg1"))
        try await client.send(.text("msg2"))
        try await client.send(.text("msg3"))

        sentMessages.withValue { messages in
            XCTAssertEqual(messages.count, 3)
            XCTAssertEqual(messages[0], .text("msg1"))
            XCTAssertEqual(messages[1], .text("msg2"))
            XCTAssertEqual(messages[2], .text("msg3"))
        }

        continuation.finish()
    }
}
