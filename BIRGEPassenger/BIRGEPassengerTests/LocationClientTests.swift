//
//  LocationClientTests.swift
//  BIRGEPassengerTests
//
//  Unit tests for LocationClient TCA Dependency.
//  IOS-015 — LocationClient TCA Dependency
//
//  Tests 1-2 use the controllable `testValue` mock.
//  Tests 3-5 use real GRDB (in-memory) with LocationSyncService.
//

import ConcurrencyExtras
import GRDB
import XCTest
@testable import BIRGECore

@MainActor
final class LocationClientTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a test client with all controllable parts exposed.
    private func makeTestClient() -> (
        client: LocationClient,
        continuation: AsyncStream<LocationUpdate>.Continuation,
        stopCalled: LockIsolated<Bool>,
        syncHandler: LockIsolated<[String]>
    ) {
        let (stream, continuation) = AsyncStream.makeStream(of: LocationUpdate.self)
        let stopCalled = LockIsolated(false)
        let syncHandler = LockIsolated<[String]>([])

        let client = LocationClient.test(
            events: stream,
            continuation: continuation,
            stopCalled: stopCalled,
            syncHandler: syncHandler
        )

        return (client, continuation, stopCalled, syncHandler)
    }

    /// Creates a sample LocationUpdate for testing.
    private func sampleUpdate(
        lat: Double = 43.238,
        lon: Double = 76.945,
        accuracy: Double = 5.0
    ) -> LocationUpdate {
        LocationUpdate(
            latitude: lat,
            longitude: lon,
            accuracy: accuracy,
            timestamp: Date()
        )
    }

    /// Creates an in-memory GRDB database with migrations applied.
    private func makeTestDatabase() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
            try db.create(table: "location_records") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ride_id", .text).notNull()
                t.column("latitude", .double).notNull()
                t.column("longitude", .double).notNull()
                t.column("timestamp", .double).notNull()
                t.column("accuracy", .double)
                t.column("synced", .integer).notNull().defaults(to: 0)
            }
        }
        return dbQueue
    }

    // MARK: - Test 1: Location Stream Emits Values

    /// Confirms `startTracking` returns a stream that yields values
    /// pushed via the continuation.
    func testLocationStreamEmitsValues() async throws {
        let (client, continuation, _, _) = makeTestClient()

        // Push two location updates
        let update1 = sampleUpdate(lat: 43.238, lon: 76.945)
        let update2 = sampleUpdate(lat: 43.240, lon: 76.950)

        continuation.yield(update1)
        continuation.yield(update2)
        continuation.finish()

        // Consume the stream
        let eventStream = await client.startTracking("ride-123")
        var receivedUpdates: [LocationUpdate] = []
        for await update in eventStream {
            receivedUpdates.append(update)
        }

        // Assert we got both updates
        XCTAssertEqual(receivedUpdates.count, 2)
        XCTAssertEqual(receivedUpdates[0].latitude, 43.238)
        XCTAssertEqual(receivedUpdates[0].longitude, 76.945)
        XCTAssertEqual(receivedUpdates[1].latitude, 43.240)
        XCTAssertEqual(receivedUpdates[1].longitude, 76.950)
    }

    // MARK: - Test 2: Stop Tracking Finishes Stream

    /// Confirms `stopTracking` finishes the stream and sets the flag.
    func testStopTrackingFinishesStream() async throws {
        let (client, continuation, stopCalled, _) = makeTestClient()

        // Start tracking
        let eventStream = await client.startTracking("ride-123")

        // Yield one event
        continuation.yield(sampleUpdate())

        // Stop tracking
        await client.stopTracking()

        // Assert stop was called
        stopCalled.withValue { called in
            XCTAssertTrue(called, "stopTracking() should set stopCalled to true")
        }

        // Consume remaining events — stream should terminate
        var events: [LocationUpdate] = []
        for await event in eventStream {
            events.append(event)
        }

        // Should have at most the one event yielded before stop
        XCTAssertTrue(events.count <= 1, "Stream should terminate after stopTracking")
    }

    // MARK: - Test 3: Sync Marks Records Synced

    /// Confirms `LocationSyncService.syncIfNeeded` fetches unsynced records,
    /// uploads them, and marks them as synced in GRDB.
    func testSyncMarksRecordsSynced() async throws {
        let dbQueue = try makeTestDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        // Insert 3 unsynced records
        for i in 0..<3 {
            let record = LocationRecord(
                rideID: "ride-sync",
                latitude: 43.238 + Double(i) * 0.001,
                longitude: 76.945,
                timestamp: Date().timeIntervalSince1970 + Double(i),
                accuracy: 5.0,
                synced: false
            )
            try await repository.insert(record)
        }

        // Verify 3 unsynced records exist
        let unsyncedBefore = try await repository.fetchUnsynced(rideID: "ride-sync")
        XCTAssertEqual(unsyncedBefore.count, 3)

        // Track what was uploaded
        var uploadedBatches: [[LocationRecord]] = []

        // Run sync
        try await LocationSyncService.syncIfNeeded(
            rideID: "ride-sync",
            repository: repository,
            uploadBatch: { batch in
                uploadedBatches.append(batch)
            }
        )

        // Assert upload was called with all 3 records
        XCTAssertEqual(uploadedBatches.count, 1)
        XCTAssertEqual(uploadedBatches[0].count, 3)

        // Assert all records are now synced
        let unsyncedAfter = try await repository.fetchUnsynced(rideID: "ride-sync")
        XCTAssertEqual(unsyncedAfter.count, 0, "All records should be marked as synced")
    }

    // MARK: - Test 4: Sync Batches In Groups Of 200

    /// Confirms that 500 unsynced records are batched into 3 upload calls
    /// (200 + 200 + 100).
    func testSyncBatchesInGroupsOf200() async throws {
        let dbQueue = try makeTestDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        // Insert 500 unsynced records in one transaction
        try await dbQueue.write { db in
            for i in 0..<500 {
                var record = LocationRecord(
                    rideID: "ride-batch",
                    latitude: 43.238,
                    longitude: 76.945,
                    timestamp: Double(i),
                    accuracy: 5.0,
                    synced: false
                )
                try record.insert(db)
            }
        }

        // Track batch sizes
        var batchSizes: [Int] = []

        // Run sync
        try await LocationSyncService.syncIfNeeded(
            rideID: "ride-batch",
            repository: repository,
            uploadBatch: { batch in
                batchSizes.append(batch.count)
            }
        )

        // Assert 3 batches: 200 + 200 + 100
        XCTAssertEqual(batchSizes.count, 3, "500 records should produce 3 batches")
        XCTAssertEqual(batchSizes[0], 200)
        XCTAssertEqual(batchSizes[1], 200)
        XCTAssertEqual(batchSizes[2], 100)

        // Assert all records are now synced
        let unsyncedAfter = try await repository.fetchUnsynced(rideID: "ride-batch")
        XCTAssertEqual(unsyncedAfter.count, 0)
    }

    // MARK: - Test 5: Sync Idempotent When No Records

    /// Confirms that calling sync with 0 unsynced records returns
    /// immediately without calling the upload closure.
    func testSyncIdempotentWhenNoRecords() async throws {
        let dbQueue = try makeTestDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        // No records inserted — database is empty

        var uploadCallCount = 0

        // Run sync
        try await LocationSyncService.syncIfNeeded(
            rideID: "ride-empty",
            repository: repository,
            uploadBatch: { _ in
                uploadCallCount += 1
            }
        )

        // Assert upload was never called
        XCTAssertEqual(uploadCallCount, 0, "Upload should not be called when no unsynced records exist")
    }
}
