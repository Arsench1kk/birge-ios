//
//  LiveLocationClient.swift
//  BIRGECore
//
//  Production implementation of LocationClient using CLLocationManager.
//  IOS-015 — LocationClient TCA Dependency
//
//  Architecture ref: iOS_Architecture.md Section 5
//
//  Design:
//  - LocationManagerCoordinator: @MainActor class owning CLLocationManager
//  - LiveLocationActor: actor-isolated, manages GRDB + stream lifecycle
//  - GRDB write on every location update (offline-first)
//  - No @MainActor on GRDB operations
//

import CoreLocation
import Foundation

// MARK: - Location Manager Coordinator

/// `@MainActor`-isolated coordinator that owns `CLLocationManager`.
///
/// `CLLocationManager` and its delegate must live on the main thread.
/// This class encapsulates all main-thread interactions; the actor
/// communicates with it only through `@MainActor`-isolated methods.
@MainActor
final class LocationManagerCoordinator: NSObject, CLLocationManagerDelegate {

    private var manager: CLLocationManager?

    /// Called for each location update with a `LocationUpdate` value.
    /// The closure is `@Sendable` to safely cross to the actor.
    var onLocationUpdate: (@Sendable (LocationUpdate) -> Void)?

    // MARK: - Lifecycle

    func start() {
        let mgr = CLLocationManager()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBest
        mgr.distanceFilter = 5 // meters — avoid noisy updates
        mgr.allowsBackgroundLocationUpdates = Bundle.main.bundleIdentifier?.contains("BIRGEDrive") == true
        mgr.pausesLocationUpdatesAutomatically = false

        // Request authorization if needed
        if mgr.authorizationStatus == .notDetermined {
            if Bundle.main.bundleIdentifier?.contains("BIRGEDrive") == true {
                mgr.requestAlwaysAuthorization()
            } else {
                mgr.requestWhenInUseAuthorization()
            }
        }

        mgr.startUpdatingLocation()
        self.manager = mgr
    }

    func stop() {
        manager?.stopUpdatingLocation()
        manager?.delegate = nil
        manager = nil
        onLocationUpdate = nil
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        let update = LocationUpdate(from: location)
        // Capture closure before dispatching — it's @Sendable so this is safe
        let handler = MainActor.assumeIsolated { self.onLocationUpdate }
        handler?(update)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Authorization changes handled implicitly — CLLocationManager
        // will start delivering locations once authorized.
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: any Error
    ) {
        // Location errors are non-fatal for our use case.
        // CLLocationManager will continue attempting to deliver locations.
        #if DEBUG
        print("[LocationManagerCoordinator] didFailWithError: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - Live Location Actor

/// Actor-isolated production implementation of `LocationClient`.
///
/// Manages the GRDB writes and `AsyncStream` lifecycle. Delegates
/// `CLLocationManager` interactions to `LocationManagerCoordinator`
/// which lives on `@MainActor`.
///
/// Per iOS_Agent_Context.md:
/// - GPS coordinates ALWAYS written to GRDB even without network
/// - Background queue always — never `@MainActor` on GRDB operations
/// - Bulk insert: 100–200 records at a time (handled by LocationSyncService)
actor LiveLocationActor {

    // MARK: - Properties

    private var coordinator: LocationManagerCoordinator?
    private var continuation: AsyncStream<LocationUpdate>.Continuation?
    private var currentRideID: String?
    private var repository: LocationRepository?

    // MARK: - Start Tracking

    /// Starts GPS tracking for the given ride.
    ///
    /// - Creates `LocationManagerCoordinator` on `@MainActor`
    /// - Sets up GRDB writes on every location update
    /// - Returns an `AsyncStream` for the TCA reducer to consume
    ///
    /// - Parameter rideID: The active ride identifier for GRDB persistence.
    /// - Returns: An `AsyncStream<LocationUpdate>` that yields continuously.
    func startTracking(rideID: String) async -> AsyncStream<LocationUpdate> {
        // Stop any existing tracking session
        await stopTracking()

        self.currentRideID = rideID

        // Initialize repository with shared DatabaseManager
        do {
            let dbQueue = try await DatabaseManager.shared.dbQueue
            self.repository = LocationRepository(dbQueue: dbQueue)
        } catch {
            #if DEBUG
            print("[LiveLocationActor] Failed to initialize repository: \(error)")
            #endif
        }

        let (stream, continuation) = AsyncStream.makeStream(of: LocationUpdate.self)
        self.continuation = continuation

        // Capture what we need for the closure
        let repo = self.repository
        let ride = rideID

        // Create coordinator on MainActor and wire up the callback
        let coord = await LocationManagerCoordinator()
        self.coordinator = coord

        await MainActor.run {
            coord.onLocationUpdate = { update in
                // Write to GRDB first (offline-first rule), then yield to stream
                Task {
                    if let repo {
                        let record = LocationRecord(
                            rideID: ride,
                            latitude: update.latitude,
                            longitude: update.longitude,
                            timestamp: update.timestamp.timeIntervalSince1970,
                            accuracy: update.accuracy,
                            synced: false
                        )
                        do {
                            try await repo.insert(record)
                        } catch {
                            #if DEBUG
                            print("[LiveLocationActor] GRDB insert failed: \(error)")
                            #endif
                        }
                    }

                    // Yield to the stream (for the TCA reducer)
                    continuation.yield(update)
                }
            }

            coord.start()
        }

        return stream
    }

    // MARK: - Stop Tracking

    /// Stops GPS tracking and finishes the stream.
    func stopTracking() async {
        continuation?.finish()
        continuation = nil
        currentRideID = nil

        if let coord = coordinator {
            await MainActor.run {
                coord.stop()
            }
        }
        coordinator = nil
        repository = nil
    }

    // MARK: - Sync

    /// Bulk-syncs unsynced GRDB records for the given ride.
    /// Delegates to `LocationSyncService`.
    func syncPendingLocations(rideID: String) async throws {
        let repo: LocationRepository
        if let existing = repository {
            repo = existing
        } else {
            let dbQueue = try await DatabaseManager.shared.dbQueue
            repo = LocationRepository(dbQueue: dbQueue)
        }

        try await LocationSyncService.syncIfNeeded(
            rideID: rideID,
            repository: repo,
            uploadBatch: { records in
                _ = try await APIClient.liveValue.uploadLocationsBulk(rideID, records)
            }
        )
    }
}
