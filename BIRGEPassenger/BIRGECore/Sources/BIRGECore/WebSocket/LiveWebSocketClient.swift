//
//  LiveWebSocketClient.swift
//  BIRGECore
//
//  Production WebSocket implementation using URLSessionWebSocketTask.
//  IOS-014 — WebSocketClient TCA Dependency
//
//  Architecture ref: iOS_Architecture.md Section 4
//  Reconnect ref: iOS_Agent_Context.md — WebSocket Reconnect
//
//  Fix (2026-05-04): .connected is now deferred until the first
//  successful message arrives, avoiding a false-positive connected
//  state when the HTTP upgrade or JWT verification fails.
//
//  Design decisions:
//  - Actor isolation: all URLSessionWebSocketTask interactions happen
//    on a single serial actor (`LiveWebSocketActor`) — never @MainActor.
//  - Ping: every 5 seconds via a detached Task; cancelled on disconnect.
//  - Backoff: exponential 2→4→8s; after 3 consecutive
//    failures yield terminal .error and close the stream.
//  - Cancellation-safe: cancelling the consuming Task calls
//    task.cancel(with:reason:) and stops the ping loop.
//

import Foundation
import os.log

private let wsLog = Logger(
    subsystem: "kz.birge.passenger",
    category: "WebSocket"
)

// MARK: - LiveWebSocketActor

/// Actor-isolated WebSocket manager.
///
/// All `URLSessionWebSocketTask` interactions are serialized through
/// this actor. This guarantees thread safety without `@MainActor`
/// and satisfies Swift 6 strict concurrency.
///
/// `@unchecked Sendable` is NOT used — the actor boundary provides
/// the required isolation.
actor LiveWebSocketActor {

    // MARK: - Configuration

    /// Maximum reconnect attempts before giving up.
    private let maxConsecutiveFailures = 5

    /// Ping interval in seconds.
    private let pingInterval: Duration = .seconds(10)

    // MARK: - State

    private var task: URLSessionWebSocketTask?
    private var pingLoop: Task<Void, Never>?
    private var continuation: AsyncStream<WebSocketEvent>.Continuation?
    private var url: URL?
    private var consecutiveFailures: Int = 0
    private var isDisconnecting: Bool = false
    private var hasYieldedConnected: Bool = false

    // MARK: - Connect

    /// Opens a WebSocket connection and returns a stream of events.
    ///
    /// The returned `AsyncStream` yields events continuously until:
    /// - `disconnect()` is called
    /// - The consuming Task is cancelled
    /// - 5 consecutive reconnect failures occur
    func connect(to url: URL) -> AsyncStream<WebSocketEvent> {
        // Redact token from log for security
        let safeURL = url.absoluteString.components(separatedBy: "token=").first ?? url.absoluteString
        wsLog.info("[WS] connect requested: \(safeURL, privacy: .public)...")

        self.url = url
        self.consecutiveFailures = 0
        self.isDisconnecting = false
        self.hasYieldedConnected = false

        let (stream, continuation) = AsyncStream.makeStream(of: WebSocketEvent.self)
        self.continuation = continuation

        // Cleanup on stream termination (including Task cancellation)
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { await self.handleStreamTermination() }
        }

        // Start the initial connection
        Task { [weak self] in
            await self?.establishConnection()
        }

        return stream
    }

    // MARK: - Send

    /// Sends a message through the active WebSocket connection.
    ///
    /// - Throws: `WebSocketError.transportError` if no active connection
    ///           or the send fails.
    func send(_ message: WebSocketMessage) async throws {
        guard let task else {
            throw WebSocketError.transportError("No active WebSocket connection")
        }

        let wsMessage: URLSessionWebSocketTask.Message
        switch message {
        case .text(let string):
            wsMessage = .string(string)
        case .data(let data):
            wsMessage = .data(data)
        }

        do {
            try await task.send(wsMessage)
        } catch {
            throw WebSocketError.from(error)
        }
    }

    // MARK: - Disconnect

    /// Gracefully closes the WebSocket connection.
    ///
    /// Cancels the ping loop, closes the task with `.normalClosure`,
    /// and finishes the event stream.
    func disconnect() {
        wsLog.info("[WS] disconnect() called")
        isDisconnecting = true
        stopPingLoop()

        task?.cancel(with: .normalClosure, reason: nil)
        task = nil

        continuation?.yield(.disconnected(.normalClosure, nil))
        continuation?.finish()
        continuation = nil
    }

    // MARK: - Private — Connection Lifecycle

    /// Creates a new `URLSessionWebSocketTask`, resumes it,
    /// yields `.connected`, and starts the receive + ping loops.
    private func establishConnection() {
        guard let url, !isDisconnecting else {
            wsLog.warning("[WS] establishConnection skipped (url=\(self.url != nil), disconnecting=\(self.isDisconnecting))")
            return
        }

        wsLog.info("[WS] establishing connection (attempt \(self.consecutiveFailures + 1))...")

        let newTask = URLSession.shared.webSocketTask(with: url)
        self.task = newTask
        newTask.resume()

        // NOTE: Do NOT yield .connected here.
        // URLSessionWebSocketTask.resume() only *begins* the HTTP upgrade.
        // If the handshake fails (bad JWT, 403, 404), receive() will throw
        // immediately, and we would have already told the UI we were connected.
        // Instead, we yield .connected on the first successful receive().

        startPingLoop()
        startReceiveLoop()
    }

    /// Continuously receives messages from the WebSocket task.
    /// On error → triggers reconnect with backoff.
    private func startReceiveLoop() {
        guard let task else {
            wsLog.warning("[WS] startReceiveLoop: no active task")
            return
        }

        Task { [weak self] in
            do {
                let message = try await task.receive()
                guard let self else { return }

                // First successful receive → mark connection as established
                if await !self.hasYieldedConnected {
                    wsLog.info("[WS] first message received — connection confirmed")
                    await self.markConnected()
                }

                switch message {
                case .string(let text):
                    wsLog.debug("[WS] recv text (\(text.prefix(120), privacy: .public))")
                    await self.continuation?.yield(.message(.text(text)))
                case .data(let data):
                    wsLog.debug("[WS] recv data (\(data.count) bytes)")
                    await self.continuation?.yield(.message(.data(data)))
                @unknown default:
                    break
                }

                // Reset failures on successful receive
                await self.resetFailures()

                // Continue receiving
                await self.startReceiveLoop()

            } catch {
                guard let self else { return }

                // Check if this was an intentional disconnect
                guard await !self.isDisconnecting else {
                    wsLog.info("[WS] receive error during disconnect — ignoring")
                    return
                }

                // Check for Task cancellation
                guard !Task.isCancelled else {
                    wsLog.info("[WS] receive task cancelled")
                    return
                }

                wsLog.error("[WS] receive error: \(error.localizedDescription, privacy: .public)")
                await self.handleConnectionFailure(error: error)
            }
        }
    }

    /// Yields `.connected` exactly once per connection attempt.
    private func markConnected() {
        guard !hasYieldedConnected else { return }
        hasYieldedConnected = true
        consecutiveFailures = 0
        continuation?.yield(.connected)
    }

    /// Resets the failure counter on a successful receive.
    private func resetFailures() {
        consecutiveFailures = 0
    }

    // MARK: - Private — Ping Loop

    /// Starts a ping loop that fires every 5 seconds.
    /// If a ping fails, the connection is treated as broken
    /// and reconnect is triggered.
    private func startPingLoop() {
        stopPingLoop()

        pingLoop = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(10))
                } catch {
                    // Task was cancelled
                    return
                }

                guard let self else { return }
                await self.performPing()
            }
        }
    }

    /// Sends a single ping and handles the result.
    private func performPing() {
        guard let task, !isDisconnecting else { return }

        task.sendPing { [weak self] error in
            guard let self else { return }
            if let error {
                wsLog.warning("[WS] ping failed: \(error.localizedDescription)")
                Task {
                    await self.handleConnectionFailure(error: error)
                }
            } else {
                wsLog.debug("[WS] ping OK")
                Task {
                    // Successful ping also confirms connection
                    if await !self.hasYieldedConnected {
                        wsLog.info("[WS] ping success — connection confirmed")
                        await self.markConnected()
                    }
                }
            }
        }
    }

    /// Cancels the active ping loop.
    private func stopPingLoop() {
        pingLoop?.cancel()
        pingLoop = nil
    }

    // MARK: - Private — Reconnect with Backoff

    /// Handles a connection failure: increments the failure counter,
    /// checks if max retries exceeded, and schedules a reconnect
    /// with exponential backoff.
    private func handleConnectionFailure(error: any Error) {
        guard !isDisconnecting else { return }

        stopPingLoop()
        task?.cancel(with: .abnormalClosure, reason: nil)
        task = nil

        consecutiveFailures += 1

        wsLog.warning("[WS] connection failure #\(self.consecutiveFailures)/\(self.maxConsecutiveFailures): \(error.localizedDescription, privacy: .public)")

        // After max consecutive failures → yield terminal error, close stream
        guard consecutiveFailures <= maxConsecutiveFailures else {
            wsLog.error("[WS] max retries exceeded — giving up")
            continuation?.yield(.error(.maxRetriesExceeded))
            continuation?.finish()
            continuation = nil
            return
        }

        // Only yield disconnected if we had previously been connected.
        // If we never connected, don't spam the UI with disconnect events
        // until we've exhausted retries.
        if hasYieldedConnected {
            continuation?.yield(
                .disconnected(
                    .abnormalClosure,
                    "Connection lost: \(error.localizedDescription)"
                )
            )
        }

        // Reset connected flag for next attempt
        hasYieldedConnected = false

        // Schedule reconnect with exponential backoff
        let delay = backoffDelay(for: consecutiveFailures)
        wsLog.info("[WS] will retry in \(delay) ...")

        Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                // Task cancelled during backoff
                return
            }

            guard let self else { return }
            guard await !self.isDisconnecting else { return }
            await self.establishConnection()
        }
    }

    /// Calculates the backoff delay for a given attempt number.
    ///
    /// - Attempt 1: 2s
    /// - Attempt 2: 4s
    /// - Attempt 3: 8s
    private func backoffDelay(for attempt: Int) -> Duration {
        let seconds = min(pow(2.0, Double(attempt)), 30.0)
        return .seconds(seconds)
    }

    // MARK: - Private — Stream Termination

    /// Called when the `AsyncStream` terminates — either via
    /// `continuation.finish()`, Task cancellation, or deallocation.
    /// Ensures all resources are cleaned up.
    private func handleStreamTermination() {
        wsLog.info("[WS] stream terminated — cleaning up")
        stopPingLoop()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isDisconnecting = true
    }
}
