//
//  RideEvent.swift
//  BIRGECore
//
//  WebSocket event payload models for ride lifecycle events.
//  IOS-016 — RideFeature State Machine
//
//  Architecture ref: WebSocket_Hub_Architecture.md Section 4
//
//  Payload structure mirrors the backend exactly:
//  {
//    "event": "ride.status_changed",
//    "ride_id": "uuid",
//    "payload": { ... },
//    "timestamp_ms": 1714000000000
//  }
//

import Foundation

/// A ride lifecycle event received via WebSocket.
///
/// Per WebSocket_Hub_Architecture.md Section 4:
/// - `ride.status_changed` — FSM state transition
/// - `ride.location_update` — driver GPS update (5s interval)
/// - `ride.eta_updated` — OSRM recalculation
public struct RideEvent: Decodable, Sendable {
    /// Event type string: "ride.status_changed", "ride.location_update", "ride.eta_updated"
    public let event: String

    /// The ride this event belongs to.
    public let rideId: String

    /// Event-specific payload data.
    public let payload: RideEventPayload

    /// Server timestamp in milliseconds since epoch.
    public let timestampMs: Int64

    enum CodingKeys: String, CodingKey {
        case event
        case rideId = "ride_id"
        case payload
        case timestampMs = "timestamp_ms"
    }
}

/// Payload for a `RideEvent`. Fields are optional because different
/// event types populate different subsets.
public struct RideEventPayload: Decodable, Sendable {
    // MARK: - Status Changed

    /// New ride status (for "ride.status_changed" events).
    public let status: String?

    // MARK: - Location Update

    /// Driver latitude (for "ride.location_update" events).
    public let lat: Double?

    /// Driver longitude (for "ride.location_update" events).
    public let lng: Double?

    /// Driver heading in degrees (for "ride.location_update" events).
    public let headingDeg: Double?

    /// Driver speed in km/h (for "ride.location_update" events).
    public let speedKmh: Double?

    // MARK: - ETA

    /// Estimated time of arrival in seconds (for "ride.eta_updated"
    /// and sometimes included in "ride.location_update").
    public let etaSeconds: Int?

    // MARK: - Passenger Wait

    /// 4-digit verification code shown during PASSENGER_WAIT state.
    public let verificationCode: String?

    // MARK: - Cancellation

    /// Reason for cancellation (for cancelled status events).
    public let cancellationReason: String?

    // MARK: - Driver Info (on matched/accepted)

    /// Driver's display name.
    public let driverName: String?

    /// Driver's rating.
    public let driverRating: Double?

    /// Driver's vehicle description.
    public let driverVehicle: String?

    /// Driver's license plate.
    public let driverPlate: String?

    enum CodingKeys: String, CodingKey {
        case status
        case lat, lng
        case headingDeg = "heading_deg"
        case speedKmh = "speed_kmh"
        case etaSeconds = "eta_seconds"
        case verificationCode = "verification_code"
        case cancellationReason = "cancellation_reason"
        case driverName = "driver_name"
        case driverRating = "driver_rating"
        case driverVehicle = "driver_vehicle"
        case driverPlate = "driver_plate"
    }
}

// MARK: - Event Type Constants

extension RideEvent {
    /// Known event type constants.
    public enum EventType {
        public static let statusChanged = "ride.status_changed"
        public static let locationUpdate = "ride.location_update"
        public static let etaUpdated = "ride.eta_updated"
    }
}
