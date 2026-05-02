//
//  LocationClient.swift
//  BIRGECore
//
//  TCA Dependency interface for GPS location tracking.
//  IOS-015 — LocationClient TCA Dependency
//
//  Architecture ref: iOS_Architecture.md Section 5,
//                    iOS_Agent_Context.md — GPS rules
//

import ComposableArchitecture
import CoreLocation
import Foundation

// MARK: - Location Update

/// Lightweight, Sendable wrapper for a GPS location update.
///
/// Avoids passing non-`Sendable` `CLLocation` across isolation
/// boundaries. Contains only the fields needed for GRDB persistence
/// and UI display.
public struct LocationUpdate: Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double
    public let timestamp: Date

    public init(
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        timestamp: Date
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.timestamp = timestamp
    }

    /// Convenience initializer from `CLLocation`.
    public init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.accuracy = location.horizontalAccuracy
        self.timestamp = location.timestamp
    }
}

// MARK: - Cancellation ID

/// Hashable identifier for `.cancellable(id:)` lifecycle management.
///
/// Usage in a Reducer:
/// ```swift
/// case .startLocationTracking:
///     return .run { send in
///         for await location in locationClient.startTracking(rideID) {
///             await send(.locationUpdated(location))
///         }
///     }
///     .cancellable(id: LocationTrackingID.self)
///
/// case .stopLocationTracking:
///     return .cancel(id: LocationTrackingID.self)
/// ```
public enum LocationTrackingID: Hashable, Sendable {}

// MARK: - Location Client

/// TCA dependency for GPS location tracking and offline sync.
///
/// Usage in a Reducer:
/// ```swift
/// @Dependency(\.locationClient) var locationClient
/// ```
///
/// Never instantiate directly — always inject via `@Dependency`.
public struct LocationClient: Sendable {
    /// Starts GPS tracking for a ride. Returns an `AsyncStream` that
    /// yields `LocationUpdate` values continuously until stopped.
    /// Each update is also persisted to GRDB (offline-first).
    public var startTracking: @Sendable (_ rideID: String) async -> AsyncStream<LocationUpdate>

    /// Stops GPS tracking and finishes the stream.
    public var stopTracking: @Sendable () async -> Void

    /// Bulk-syncs unsynced GRDB records for the given ride to the backend.
    /// Idempotent — safe to call multiple times. Batches 100-200 records.
    public var syncPendingLocations: @Sendable (_ rideID: String) async throws -> Void

    public init(
        startTracking: @escaping @Sendable (_ rideID: String) async -> AsyncStream<LocationUpdate>,
        stopTracking: @escaping @Sendable () async -> Void,
        syncPendingLocations: @escaping @Sendable (_ rideID: String) async throws -> Void
    ) {
        self.startTracking = startTracking
        self.stopTracking = stopTracking
        self.syncPendingLocations = syncPendingLocations
    }
}

// MARK: - DependencyKey

extension LocationClient: DependencyKey {
    /// Production implementation backed by `CLLocationManager`.
    /// See `LiveLocationClient.swift` for full implementation.
    public static var liveValue: LocationClient {
        let actor = LiveLocationActor()
        return LocationClient(
            startTracking: { rideID in
                await actor.startTracking(rideID: rideID)
            },
            stopTracking: {
                await actor.stopTracking()
            },
            syncPendingLocations: { rideID in
                try await actor.syncPendingLocations(rideID: rideID)
            }
        )
    }

    /// Controllable mock for unit tests.
    ///
    /// Returns a client backed by `AsyncStream.makeStream()` so tests
    /// can push `LocationUpdate` values via the continuation.
    ///
    /// Usage in tests:
    /// ```swift
    /// let (client, continuation, stopCalled) = LocationClient.makeTest()
    /// continuation.yield(LocationUpdate(...))
    /// // assert location flows through the reducer
    /// ```
    public static var testValue: LocationClient {
        let (stream, continuation) = AsyncStream.makeStream(of: LocationUpdate.self)
        let stopCalled = LockIsolated(false)

        return .test(
            events: stream,
            continuation: continuation,
            stopCalled: stopCalled
        )
    }

    /// Factory for test clients with caller-controlled streams.
    /// Preferred over `testValue` when you need direct access to
    /// the continuation and captured state.
    public static func test(
        events: AsyncStream<LocationUpdate>,
        continuation: AsyncStream<LocationUpdate>.Continuation? = nil,
        stopCalled: LockIsolated<Bool> = .init(false),
        syncHandler: LockIsolated<[String]> = .init([])
    ) -> LocationClient {
        LocationClient(
            startTracking: { _ in events },
            stopTracking: {
                stopCalled.withValue { $0 = true }
                continuation?.finish()
            },
            syncPendingLocations: { rideID in
                syncHandler.withValue { $0.append(rideID) }
            }
        )
    }
}
