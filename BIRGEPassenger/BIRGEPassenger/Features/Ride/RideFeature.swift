//
//  RideFeature.swift
//  BIRGEPassenger
//
//  Full 7-state ride lifecycle TCA Reducer.
//  IOS-016 — RideFeature State Machine
//
//  Architecture ref: Ride_State_Machine.md — 7-state FSM
//                    WebSocket_Hub_Architecture.md — event payloads
//                    iOS_Architecture.md Section 5 — GPS tracking
//
//  State transitions mirror the backend FSM exactly:
//    requested → matched → driverAccepted → driverArriving
//    → passengerWait → inProgress → completed
//    Any state → cancelled (with reason)
//

import BIRGECore
import ComposableArchitecture
import CoreLocation
import Foundation

// MARK: - Cancellation IDs

/// String identifiers avoid actor-isolated custom `Hashable` conformances in cancellable effects.
private enum RideCancelID {
    static let webSocket = "RideFeature.webSocket"
    static let tracking = "RideFeature.tracking"
    static let passengerWaitTimer = "RideFeature.passengerWaitTimer"
}

// MARK: - RideFeature

@Reducer
struct RideFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        /// The active ride identifier.
        var rideId: String

        /// Current FSM status — mirrors backend exactly.
        var status: RideStatus = .requested

        /// Live driver location from WebSocket `ride.location_update`.
        var driverLocation: Coordinate?

        /// Estimated time of arrival in seconds.
        var etaSeconds: Int?

        /// Driver display name (set on `matched`/`driverAccepted`).
        var driverName: String?

        /// Driver rating (set on `matched`/`driverAccepted`).
        var driverRating: Double?

        /// Driver vehicle description.
        var driverVehicle: String?

        /// Driver license plate.
        var driverPlate: String?

        /// 4-digit verification code for `passengerWait` state.
        var verificationCode: String?

        /// Remaining seconds of the 3-minute boarding window.
        var waitCountdownSeconds: Int?

        /// Cancellation reason (if `cancelled`).
        var cancellationReason: String?

        /// Pickup location (static, from ride origin).
        var pickupLocation: Coordinate?

        /// Network/API loading indicator.
        var isLoading: Bool = false

        /// Error message for user-facing display.
        var error: String?

        /// True after the WebSocket exhausts reconnect attempts.
        var isConnectionLost: Bool = false

        /// Consecutive WebSocket disconnect/error events seen by the reducer.
        var webSocketReconnectAttempts: Int = 0

    }

    // MARK: - Action

    enum Action: ViewAction, Sendable {
        case view(View)

        // WebSocket events (past tense — per TCA convention)
        case webSocketEventReceived(WebSocketEvent)
        case rideStatusChanged(RideStatus)
        case driverLocationUpdated(Coordinate)
        case etaUpdated(Int)

        // Internal
        case rideLoadedFromServer(RideResponse)
        case cancelConfirmed
        case errorOccurred(String)
        case errorDismissed
        case webSocketConnected
        case webSocketDisconnected
        case waitCountdownTick

        // Delegate — parent (PassengerAppFeature) handles navigation
        case delegate(Delegate)

        @CasePathable
        enum View: Sendable {
            case onAppear
            case onDisappear
            case cancelRideTapped(reason: String)
            case errorDismissed
            case backToHomeTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case completed
            case cancelled
        }
    }

    // MARK: - Dependencies

    @Dependency(\.webSocketClient) var webSocketClient
    @Dependency(\.locationClient) var locationClient
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.keychainClient) var keychainClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: Lifecycle

            case .view(.onAppear):
                let rideId = state.rideId
                let accessTokenKey = KeychainClient.Keys.accessToken
                let apiClient = self.apiClient
                let keychainClient = self.keychainClient
                let webSocketClient = self.webSocketClient
                return .run { send in
                    do {
                        guard let token = try await Self.webSocketAccessToken(
                            apiClient: apiClient,
                            keychainClient: keychainClient,
                            accessTokenKey: accessTokenKey
                        ) else {
                            await send(.errorOccurred("Не удалось авторизовать WebSocket."))
                            return
                        }

                        let url = try Self.webSocketURL(rideId: rideId, token: token)
                        let eventStream = await webSocketClient.connect(url)
                        for await event in eventStream {
                            await send(.webSocketEventReceived(event))
                        }
                    } catch {
                        await send(.errorOccurred(error.localizedDescription))
                    }
                }
                .cancellable(id: RideCancelID.webSocket, cancelInFlight: true)

            case .view(.onDisappear):
                return .merge(
                    .cancel(id: RideCancelID.webSocket),
                    .cancel(id: RideCancelID.tracking),
                    .cancel(id: RideCancelID.passengerWaitTimer),
                    .run { _ in
                        await webSocketClient.disconnect()
                        await locationClient.stopTracking()
                    }
                )

            case .view(.errorDismissed):
                return .send(.errorDismissed)

            case .view(.backToHomeTapped):
                return .merge(
                    .cancel(id: RideCancelID.webSocket),
                    .cancel(id: RideCancelID.tracking),
                    .cancel(id: RideCancelID.passengerWaitTimer),
                    .run { _ in
                        await webSocketClient.disconnect()
                        await locationClient.stopTracking()
                    },
                    .send(.delegate(.cancelled))
                )

            // MARK: WebSocket Event Processing

            case let .webSocketEventReceived(event):
                switch event {
                case .connected:
                    return .send(.webSocketConnected)

                case let .message(.text(json)):
                    if Self.isControlMessage(json) {
                        return .none
                    }
                    // Decode the RideEvent from JSON
                    guard let data = json.data(using: .utf8) else {
                        return .none
                    }
                    do {
                        let rideEvent = try JSONDecoder().decode(RideEvent.self, from: data)
                        return processRideEvent(rideEvent, state: &state)
                    } catch {
                        return .send(.errorOccurred("Failed to decode event: \(error.localizedDescription)"))
                    }

                case .message(.data):
                    // Binary messages not expected — ignore
                    return .none

                case .disconnected:
                    return .send(.webSocketDisconnected)

                case .error:
                    state.isConnectionLost = true
                    return .none
                }

            // MARK: WebSocket Connection Events

            case .webSocketConnected:
                state.isConnectionLost = false
                state.webSocketReconnectAttempts = 0
                // On reconnect, re-fetch ride state to recover missed transitions
                let rideId = state.rideId
                return .run { send in
                    do {
                        let ride = try await apiClient.fetchRide(rideId)
                        await send(.rideLoadedFromServer(ride))
                    } catch {
                        await send(.errorOccurred("Failed to fetch ride: \(error.localizedDescription)"))
                    }
                }

            case .webSocketDisconnected:
                state.webSocketReconnectAttempts += 1
                state.isConnectionLost = true
                // Recover missed transitions while the socket reconnects.
                let rideId = state.rideId
                return .run { send in
                    do {
                        let ride = try await apiClient.fetchRide(rideId)
                        await send(.rideLoadedFromServer(ride))
                    } catch {
                        await send(.errorOccurred("Failed to fetch ride: \(error.localizedDescription)"))
                    }
                }

            // MARK: State Transitions

            case let .rideStatusChanged(newStatus):
                let oldStatus = state.status
                state.status = newStatus
                state.error = nil

                return handleStatusTransition(
                    from: oldStatus,
                    to: newStatus,
                    state: &state
                )

            case let .driverLocationUpdated(coordinate):
                state.driverLocation = coordinate
                return .none

            case let .etaUpdated(seconds):
                state.etaSeconds = seconds
                return .none

            // MARK: Server State Recovery

            case let .rideLoadedFromServer(ride):
                state.isLoading = false
                if let driverName = ride.driverName {
                    state.driverName = driverName
                }
                if let driverRating = ride.driverRating {
                    state.driverRating = driverRating
                }
                if let driverVehicle = ride.driverVehicle {
                    state.driverVehicle = driverVehicle
                }
                if let driverPlate = ride.driverPlate {
                    state.driverPlate = driverPlate
                }
                if let etaSeconds = ride.etaSeconds {
                    state.etaSeconds = etaSeconds
                }
                if let verificationCode = ride.verificationCode {
                    state.verificationCode = verificationCode
                }

                if let lat = ride.pickupLatitude, let lng = ride.pickupLongitude {
                    state.pickupLocation = Coordinate(latitude: lat, longitude: lng)
                }

                // Apply the server status if it differs
                guard let serverStatus = RideStatus(rawValue: ride.status) else {
                    return .none
                }
                if serverStatus != state.status {
                    return .send(.rideStatusChanged(serverStatus))
                }
                return .none

            // MARK: User Actions

            case let .view(.cancelRideTapped(reason)):
                state.isLoading = true
                state.cancellationReason = reason
                let rideId = state.rideId
                return .run { send in
                    do {
                        try await apiClient.cancelRide(rideId, reason)
                        await send(.cancelConfirmed)
                    } catch {
                        await send(.errorOccurred("Cancel failed: \(error.localizedDescription)"))
                    }
                }

            case .cancelConfirmed:
                state.isLoading = false
                state.status = .cancelled
                return .merge(
                    .cancel(id: RideCancelID.webSocket),
                    .cancel(id: RideCancelID.tracking),
                    .cancel(id: RideCancelID.passengerWaitTimer)
                )

            // MARK: Passenger Wait Countdown

            case .waitCountdownTick:
                guard state.status == .passengerWait else {
                    return .cancel(id: RideCancelID.passengerWaitTimer)
                }
                if let remaining = state.waitCountdownSeconds, remaining > 0 {
                    state.waitCountdownSeconds = remaining - 1
                }
                return .none

            // MARK: Error

            case let .errorOccurred(message):
                state.isLoading = false
                state.error = message
                if message.contains("maxRetriesExceeded") {
                    state.isConnectionLost = true
                }
                return .none

            case .errorDismissed:
                state.error = nil
                return .none

            // MARK: Delegate

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Private Helpers

    nonisolated private static func webSocketURL(rideId: String, token: String) throws -> URL {
        try BIRGEAPIConfiguration.rideWebSocketURL(rideID: rideId, token: token)
    }

    /// Returns true for backend control frames like
    /// {"type":"connected"} or {"type":"subscribed"}.
    nonisolated private static func isControlMessage(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = dict["type"] as? String
        else { return false }
        return type == "connected" || type == "subscribed"
    }

    nonisolated private static func webSocketAccessToken(
        apiClient: APIClient,
        keychainClient: KeychainClient,
        accessTokenKey: String
    ) async throws -> String? {
        do {
            return try await apiClient.refreshAccessToken()
        } catch {
            return try keychainClient.load(accessTokenKey)
        }
    }

    /// Process a decoded `RideEvent` and dispatch the appropriate action.
    private func processRideEvent(
        _ event: RideEvent,
        state: inout State
    ) -> Effect<Action> {
        switch event.event {
        case RideEvent.EventType.statusChanged:
            guard let statusString = event.payload.status,
                  let status = Self.rideStatus(from: statusString) else {
                return .none
            }

            applyLifecyclePayload(event.payload, to: &state)

            return .send(.rideStatusChanged(status))

        case RideEvent.EventType.driverAccepted:
            applyLifecyclePayload(event.payload, to: &state)
            return .send(.rideStatusChanged(.driverAccepted))

        case RideEvent.EventType.driverArriving:
            applyLifecyclePayload(event.payload, to: &state)
            return .send(.rideStatusChanged(.driverArriving))

        case RideEvent.EventType.driverArrived:
            applyLifecyclePayload(event.payload, to: &state)
            return .send(.rideStatusChanged(.passengerWait))

        case RideEvent.EventType.rideStarted:
            applyLifecyclePayload(event.payload, to: &state)
            return .send(.rideStatusChanged(.inProgress))

        case RideEvent.EventType.rideCompleted:
            applyLifecyclePayload(event.payload, to: &state)
            return .send(.rideStatusChanged(.completed))

        case RideEvent.EventType.rideCancelled:
            applyLifecyclePayload(event.payload, to: &state)
            return .send(.rideStatusChanged(.cancelled))

        case RideEvent.EventType.locationUpdate:
            guard let lat = event.payload.lat,
                  let lng = event.payload.lng else {
                return .none
            }
            let coordinate = Coordinate(latitude: lat, longitude: lng)

            // Location updates often include ETA
            var effects: [Effect<Action>] = [
                .send(.driverLocationUpdated(coordinate))
            ]
            if let eta = event.payload.etaSeconds {
                effects.append(.send(.etaUpdated(eta)))
            }
            return .merge(effects)

        case RideEvent.EventType.etaUpdated:
            guard let eta = event.payload.etaSeconds else {
                return .none
            }
            return .send(.etaUpdated(eta))

        default:
            return .none
        }
    }

    private func applyLifecyclePayload(_ payload: RideEventPayload, to state: inout State) {
        if let name = payload.driverName {
            state.driverName = name
        }
        if let rating = payload.driverRating {
            state.driverRating = rating
        }
        if let vehicle = payload.driverVehicle {
            state.driverVehicle = vehicle
        }
        if let plate = payload.driverPlate {
            state.driverPlate = plate
        }
        if let code = payload.verificationCode {
            state.verificationCode = code
        }
        if let reason = payload.cancellationReason {
            state.cancellationReason = reason
        }
        if let etaSeconds = payload.etaSeconds {
            state.etaSeconds = etaSeconds
        }
    }

    nonisolated private static func rideStatus(from rawValue: String) -> RideStatus? {
        switch rawValue {
        case RideStatus.requested.rawValue:
            return .requested
        case RideStatus.matched.rawValue:
            return .matched
        case RideStatus.driverAccepted.rawValue, "driver_accepted":
            return .driverAccepted
        case RideStatus.driverArriving.rawValue, "driver_arriving":
            return .driverArriving
        case RideStatus.passengerWait.rawValue, "driver_arrived", "passenger_wait":
            return .passengerWait
        case RideStatus.inProgress.rawValue, "ride_started", "started", "in_progress":
            return .inProgress
        case RideStatus.completed.rawValue, "ride_completed":
            return .completed
        case RideStatus.cancelled.rawValue, "ride_cancelled":
            return .cancelled
        default:
            return nil
        }
    }

    /// Handle state-specific side effects when transitioning between statuses.
    private func handleStatusTransition(
        from oldStatus: RideStatus,
        to newStatus: RideStatus,
        state: inout State
    ) -> Effect<Action> {
        switch newStatus {

        case .driverArriving:
            // Start GPS tracking for the ride
                let rideId = state.rideId
                return .run { send in
                    let locationStream = await locationClient.startTracking(rideId)
                for await _ in locationStream {
                    // GPS updates are written to GRDB by LocationClient internally
                    // The passenger app doesn't need to process them in the reducer
                    // Driver location comes via WebSocket, not passenger's GPS
                }
            }
            .cancellable(id: RideCancelID.tracking)

        case .passengerWait:
            // Start 3-minute countdown timer
            state.waitCountdownSeconds = 180
            return .run { send in
                for _ in 1...180 {
                    try await Task.sleep(for: .seconds(1))
                    await send(.waitCountdownTick)
                }
            }
            .cancellable(id: RideCancelID.passengerWaitTimer)

        case .inProgress:
            // Cancel the wait countdown (if transitioning from passengerWait)
            return .cancel(id: RideCancelID.passengerWaitTimer)

        case .completed:
            // Terminal state — cancel all side effects, notify parent
            return .merge(
                .cancel(id: RideCancelID.webSocket),
                .cancel(id: RideCancelID.tracking),
                .cancel(id: RideCancelID.passengerWaitTimer),
                .run { _ in
                    await locationClient.stopTracking()
                },
                .send(.delegate(.completed))
            )

        case .cancelled:
            // Terminal state — keep the cancellation sheet visible until
            // the user explicitly navigates home.
            return .merge(
                .cancel(id: RideCancelID.webSocket),
                .cancel(id: RideCancelID.tracking),
                .cancel(id: RideCancelID.passengerWaitTimer),
                .run { _ in
                    await locationClient.stopTracking()
                }
            )

        case .requested, .matched, .driverAccepted:
            // No side effects needed for these transitions
            return .none
        }
    }
}
