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
    private let maxConsecutiveFailures = 3

    /// Ping interval in seconds.
    private let pingInterval: Duration = .seconds(5)

    // MARK: - State

    private var task: URLSessionWebSocketTask?
    private var pingLoop: Task<Void, Never>?
    private var continuation: AsyncStream<WebSocketEvent>.Continuation?
    private var url: URL?
    private var consecutiveFailures: Int = 0
    private var isDisconnecting: Bool = false

    // MARK: - Connect

    /// Opens a WebSocket connection and returns a stream of events.
    ///
    /// The returned `AsyncStream` yields events continuously until:
    /// - `disconnect()` is called
    /// - The consuming Task is cancelled
    /// - 5 consecutive reconnect failures occur
    func connect(to url: URL) -> AsyncStream<WebSocketEvent> {
        self.url = url
        self.consecutiveFailures = 0
        self.isDisconnecting = false

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
        guard let url, !isDisconnecting else { return }

        let newTask = URLSession.shared.webSocketTask(with: url)
        self.task = newTask
        newTask.resume()

        continuation?.yield(.connected)

        startPingLoop()
        startReceiveLoop()
    }

    /// Continuously receives messages from the WebSocket task.
    /// On error → triggers reconnect with backoff.
    private func startReceiveLoop() {
        guard let task else { return }

        Task { [weak self] in
            do {
                let message = try await task.receive()
                guard let self else { return }

                switch message {
                case .string(let text):
                    await self.continuation?.yield(.message(.text(text)))
                case .data(let data):
                    await self.continuation?.yield(.message(.data(data)))
                @unknown default:
                    break
                }

                // Continue receiving
                await self.startReceiveLoop()

            } catch {
                guard let self else { return }

                // Check if this was an intentional disconnect
                guard await !self.isDisconnecting else { return }

                // Check for Task cancellation
                guard !Task.isCancelled else { return }

                await self.handleConnectionFailure(error: error)
            }
        }
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
                    try await Task.sleep(for: .seconds(5))
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
            if error != nil {
                Task {
                    await self.handleConnectionFailure(
                        error: error ?? WebSocketError.transportError("Ping failed")
                    )
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

        // After 3 consecutive failures → yield terminal error, close stream
        guard consecutiveFailures <= maxConsecutiveFailures else {
            continuation?.yield(.error(.maxRetriesExceeded))
            continuation?.finish()
            continuation = nil
            return
        }

        // Yield a disconnected event so the UI can show a banner
        continuation?.yield(
            .disconnected(
                .abnormalClosure,
                "Connection lost: \(error.localizedDescription)"
            )
        )

        // Schedule reconnect with exponential backoff
        let delay = backoffDelay(for: consecutiveFailures)

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
        let seconds = pow(2.0, Double(attempt))
        return .seconds(seconds)
    }

    // MARK: - Private — Stream Termination

    /// Called when the `AsyncStream` terminates — either via
    /// `continuation.finish()`, Task cancellation, or deallocation.
    /// Ensures all resources are cleaned up.
    private func handleStreamTermination() {
        stopPingLoop()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isDisconnecting = true
    }
}
