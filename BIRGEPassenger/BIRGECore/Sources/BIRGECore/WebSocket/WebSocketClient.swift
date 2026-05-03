//
//  WebSocketClient.swift
//  BIRGECore
//
//  TCA Dependency interface for WebSocket communication.
//  IOS-014 — WebSocketClient TCA Dependency
//
//  Architecture ref: iOS_Architecture.md Section 4,
//                    WebSocket_Hub_Architecture.md Section 5
//

import ComposableArchitecture
import Foundation

// MARK: - WebSocket Event

/// Events emitted by the WebSocket connection stream.
///
/// Mirrors the lifecycle of a `URLSessionWebSocketTask`:
/// - `.connected` — handshake complete, ready to send/receive
/// - `.message` — a frame was received
/// - `.disconnected` — clean close with code and optional reason
/// - `.error` — transport or protocol error
public enum WebSocketEvent: Sendable {
    case connected
    case message(WebSocketMessage)
    case disconnected(URLSessionWebSocketTask.CloseCode, String?)
    case error(WebSocketError)
}

// MARK: - WebSocket Message

/// A WebSocket frame — either UTF-8 text or raw binary data.
public enum WebSocketMessage: Sendable, Equatable {
    case text(String)
    case data(Data)
}

// MARK: - WebSocket Error

/// Concrete error type for WebSocket failures.
/// Using a concrete type instead of bare `Error` satisfies Swift 6
/// strict concurrency `Sendable` requirements without `@unchecked`.
public enum WebSocketError: Error, Sendable, Equatable, LocalizedError {
    case maxRetriesExceeded
    case transportError(String)
    case encodingError(String)

    public var errorDescription: String? {
        switch self {
        case .maxRetriesExceeded:
            "Maximum WebSocket reconnect attempts exceeded."
        case let .transportError(message), let .encodingError(message):
            message
        }
    }

    public static func from(_ error: any Error) -> WebSocketError {
        .transportError(error.localizedDescription)
    }
}

// MARK: - WebSocket Client

/// TCA dependency for WebSocket communication.
///
/// Usage in a Reducer:
/// ```swift
/// @Dependency(\.webSocketClient) var webSocketClient
/// ```
///
/// Never instantiate directly — always inject via `@Dependency`.
public struct WebSocketClient: Sendable {
    /// Opens a WebSocket connection to the given URL.
    /// Returns an `AsyncStream` that yields events continuously until
    /// disconnected or the stream is cancelled.
    public var connect: @Sendable (URL) async -> AsyncStream<WebSocketEvent>

    /// Sends a message through the active WebSocket connection.
    public var send: @Sendable (WebSocketMessage) async throws -> Void

    /// Gracefully closes the WebSocket connection.
    public var disconnect: @Sendable () async -> Void

    public init(
        connect: @escaping @Sendable (URL) async -> AsyncStream<WebSocketEvent>,
        send: @escaping @Sendable (WebSocketMessage) async throws -> Void,
        disconnect: @escaping @Sendable () async -> Void
    ) {
        self.connect = connect
        self.send = send
        self.disconnect = disconnect
    }
}

// MARK: - DependencyKey

extension WebSocketClient: DependencyKey {
    /// Production implementation backed by `URLSessionWebSocketTask`.
    /// See `LiveWebSocketClient.swift` for full implementation.
    public static var liveValue: WebSocketClient {
        let actor = LiveWebSocketActor()
        return WebSocketClient(
            connect: { url in
                await actor.connect(to: url)
            },
            send: { message in
                try await actor.send(message)
            },
            disconnect: {
                await actor.disconnect()
            }
        )
    }

    /// Controllable mock for unit tests.
    ///
    /// Returns a client backed by `AsyncStream.makeStream()` so tests
    /// can push events via the continuation. Captures sent messages
    /// and disconnect calls for assertions.
    ///
    /// Usage in tests:
    /// ```swift
    /// let (stream, continuation) = AsyncStream.makeStream(of: WebSocketEvent.self)
    /// let sentMessages = LockIsolated<[WebSocketMessage]>([])
    /// let disconnectCalled = LockIsolated(false)
    ///
    /// let store = TestStore(...) {
    ///     $0.webSocketClient = .test(
    ///         events: stream,
    ///         sentMessages: sentMessages,
    ///         disconnectCalled: disconnectCalled
    ///     )
    /// }
    ///
    /// continuation.yield(.connected)
    /// // assert events flow through the reducer
    /// ```
    public static var testValue: WebSocketClient {
        let (stream, continuation) = AsyncStream.makeStream(of: WebSocketEvent.self)
        let sentMessages = LockIsolated<[WebSocketMessage]>([])
        let disconnectCalled = LockIsolated(false)

        return .test(
            events: stream,
            continuation: continuation,
            sentMessages: sentMessages,
            disconnectCalled: disconnectCalled
        )
    }

    /// Factory for test clients with caller-controlled streams.
    /// Preferred over `testValue` when you need direct access to
    /// the continuation and captured state.
    public static func test(
        events: AsyncStream<WebSocketEvent>,
        continuation: AsyncStream<WebSocketEvent>.Continuation? = nil,
        sentMessages: LockIsolated<[WebSocketMessage]> = .init([]),
        disconnectCalled: LockIsolated<Bool> = .init(false)
    ) -> WebSocketClient {
        WebSocketClient(
            connect: { _ in events },
            send: { message in
                sentMessages.withValue { $0.append(message) }
            },
            disconnect: {
                disconnectCalled.withValue { $0 = true }
                continuation?.finish()
            }
        )
    }
}
