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

/// Hashable identifier for WebSocket subscription lifecycle.
private enum RideWebSocketID: Hashable {}

/// Hashable identifier for GPS tracking lifecycle.
private enum RideTrackingID: Hashable {}

/// Hashable identifier for passenger wait countdown.
private enum PassengerWaitTimerID: Hashable {}

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

        /// WebSocket URL for the ride connection.
        var wsURL: URL {
            // In production this would use the real base URL
            // For now, construct from ride ID
            URL(string: "wss://api.birge.kz/ws")
                ?? URL(string: "wss://localhost/ws")! // compile-time fallback only
        }
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

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: Lifecycle

            case .view(.onAppear):
                let url = state.wsURL
                return .run { send in
                    let eventStream = await webSocketClient.connect(url)
                    for await event in eventStream {
                        await send(.webSocketEventReceived(event))
                    }
                }
                .cancellable(id: RideWebSocketID.self, cancelInFlight: true)

            case .view(.onDisappear):
                return .merge(
                    .cancel(id: RideWebSocketID.self),
                    .cancel(id: RideTrackingID.self),
                    .cancel(id: PassengerWaitTimerID.self),
                    .run { _ in
                        await webSocketClient.disconnect()
                        await locationClient.stopTracking()
                    }
                )

            // MARK: WebSocket Event Processing

            case let .webSocketEventReceived(event):
                switch event {
                case .connected:
                    return .send(.webSocketConnected)

                case let .message(.text(json)):
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
                    // WebSocketClient handles reconnect internally
                    return .none
                }

            // MARK: WebSocket Connection Events

            case .webSocketConnected:
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
                state.driverName = ride.driverName
                state.driverRating = ride.driverRating
                state.driverVehicle = ride.driverVehicle
                state.driverPlate = ride.driverPlate
                state.etaSeconds = ride.etaSeconds
                state.verificationCode = ride.verificationCode

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
                    .cancel(id: RideWebSocketID.self),
                    .cancel(id: RideTrackingID.self),
                    .cancel(id: PassengerWaitTimerID.self),
                    .send(.delegate(.cancelled))
                )

            // MARK: Passenger Wait Countdown

            case .waitCountdownTick:
                guard state.status == .passengerWait else {
                    return .cancel(id: PassengerWaitTimerID.self)
                }
                if let remaining = state.waitCountdownSeconds, remaining > 0 {
                    state.waitCountdownSeconds = remaining - 1
                }
                return .none

            // MARK: Error

            case let .errorOccurred(message):
                state.isLoading = false
                state.error = message
                return .none

            // MARK: Delegate

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Private Helpers

    /// Process a decoded `RideEvent` and dispatch the appropriate action.
    private func processRideEvent(
        _ event: RideEvent,
        state: inout State
    ) -> Effect<Action> {
        switch event.event {
        case RideEvent.EventType.statusChanged:
            guard let statusString = event.payload.status,
                  let status = RideStatus(rawValue: statusString) else {
                return .none
            }

            // Extract driver info from status_changed payload (on matched/accepted)
            if let name = event.payload.driverName {
                state.driverName = name
            }
            if let rating = event.payload.driverRating {
                state.driverRating = rating
            }
            if let vehicle = event.payload.driverVehicle {
                state.driverVehicle = vehicle
            }
            if let plate = event.payload.driverPlate {
                state.driverPlate = plate
            }
            if let code = event.payload.verificationCode {
                state.verificationCode = code
            }
            if let reason = event.payload.cancellationReason {
                state.cancellationReason = reason
            }

            return .send(.rideStatusChanged(status))

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
            .cancellable(id: RideTrackingID.self)

        case .passengerWait:
            // Start 3-minute countdown timer
            state.waitCountdownSeconds = 180
            return .run { send in
                for _ in 1...180 {
                    try await Task.sleep(for: .seconds(1))
                    await send(.waitCountdownTick)
                }
            }
            .cancellable(id: PassengerWaitTimerID.self)

        case .inProgress:
            // Cancel the wait countdown (if transitioning from passengerWait)
            return .cancel(id: PassengerWaitTimerID.self)

        case .completed:
            // Terminal state — cancel all side effects, notify parent
            return .merge(
                .cancel(id: RideWebSocketID.self),
                .cancel(id: RideTrackingID.self),
                .cancel(id: PassengerWaitTimerID.self),
                .run { _ in
                    await locationClient.stopTracking()
                },
                .send(.delegate(.completed))
            )

        case .cancelled:
            // Terminal state — cancel all side effects, notify parent
            return .merge(
                .cancel(id: RideWebSocketID.self),
                .cancel(id: RideTrackingID.self),
                .cancel(id: PassengerWaitTimerID.self),
                .run { _ in
                    await locationClient.stopTracking()
                },
                .send(.delegate(.cancelled))
            )

        case .requested, .matched, .driverAccepted:
            // No side effects needed for these transitions
            return .none
        }
    }
}
