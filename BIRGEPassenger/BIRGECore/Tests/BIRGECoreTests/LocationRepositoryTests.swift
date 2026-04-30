//
//  LocationRepositoryTests.swift
//  BIRGECoreTests
//
//  Created for BIRGE ride-hailing app.
//

import Testing
import GRDB
@testable import BIRGECore

/// Tests for `LocationRepository` using in-memory GRDB databases.
///
/// Each test creates a fresh in-memory `DatabaseQueue` — no file I/O,
/// fully isolated, and fast.
struct LocationRepositoryTests {

    // MARK: - Helpers

    /// Create an in-memory database with migrations applied.
    private func makeInMemoryDatabase() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue(configuration: {
            var config = Configuration()
            config.journalMode = .wal
            return config
        }())

        // Apply the same migration as DatabaseManager
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_createLocationRecords") { db in
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
        try migrator.migrate(dbQueue)

        return dbQueue
    }

    /// Create a sample `LocationRecord` for testing.
    private func makeSampleRecord(
        rideID: String = "ride-123",
        latitude: Double = 43.2380,
        longitude: Double = 76.9454,
        timestamp: Double = 1_700_000_000,
        accuracy: Double? = 5.0,
        synced: Bool = false
    ) -> LocationRecord {
        LocationRecord(
            rideID: rideID,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            accuracy: accuracy,
            synced: synced
        )
    }

    // MARK: - Insert & Fetch Tests

    @Test("Insert a record, then fetchUnsynced returns it")
    func insertAndFetchUnsynced() async throws {
        let dbQueue = try makeInMemoryDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        let record = makeSampleRecord()
        try await repository.insert(record)

        let fetched = try await repository.fetchUnsynced(rideID: "ride-123")
        #expect(fetched.count == 1)
        #expect(fetched[0].rideID == "ride-123")
        #expect(fetched[0].latitude == 43.2380)
        #expect(fetched[0].longitude == 76.9454)
        #expect(fetched[0].synced == false)
        #expect(fetched[0].id != nil)
    }

    @Test("fetchUnsynced filters by rideID")
    func fetchUnsyncedFiltersByRideID() async throws {
        let dbQueue = try makeInMemoryDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        try await repository.insert(makeSampleRecord(rideID: "ride-A"))
        try await repository.insert(makeSampleRecord(rideID: "ride-B"))
        try await repository.insert(makeSampleRecord(rideID: "ride-A"))

        let fetchedA = try await repository.fetchUnsynced(rideID: "ride-A")
        #expect(fetchedA.count == 2)

        let fetchedB = try await repository.fetchUnsynced(rideID: "ride-B")
        #expect(fetchedB.count == 1)
    }

    // MARK: - Mark Synced Tests

    @Test("markSynced marks records, fetchUnsynced returns empty")
    func markSyncedThenFetchReturnsEmpty() async throws {
        let dbQueue = try makeInMemoryDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        try await repository.insert(makeSampleRecord(rideID: "ride-X"))
        try await repository.insert(makeSampleRecord(rideID: "ride-X"))

        let beforeSync = try await repository.fetchUnsynced(rideID: "ride-X")
        #expect(beforeSync.count == 2)

        let ids = beforeSync.compactMap(\.id)
        try await repository.markSynced(ids)

        let afterSync = try await repository.fetchUnsynced(rideID: "ride-X")
        #expect(afterSync.isEmpty)
    }

    @Test("markSynced with empty array does nothing")
    func markSyncedWithEmptyArray() async throws {
        let dbQueue = try makeInMemoryDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        // Should not throw
        try await repository.markSynced([])
    }

    // MARK: - Batch Insert Tests

    @Test("Batch insert multiple records at once")
    func batchInsert() async throws {
        let dbQueue = try makeInMemoryDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        let records = (0..<50).map { i in
            makeSampleRecord(
                rideID: "ride-batch",
                latitude: 43.2380 + Double(i) * 0.001,
                timestamp: 1_700_000_000 + Double(i)
            )
        }

        try await repository.insertBatch(records)

        let fetched = try await repository.fetchUnsynced(rideID: "ride-batch")
        #expect(fetched.count == 50)
    }

    @Test("fetchUnsynced returns records ordered by timestamp ascending")
    func fetchUnsyncedOrderedByTimestamp() async throws {
        let dbQueue = try makeInMemoryDatabase()
        let repository = LocationRepository(dbQueue: dbQueue)

        // Insert in reverse chronological order
        try await repository.insert(
            makeSampleRecord(rideID: "ride-order", timestamp: 3_000)
        )
        try await repository.insert(
            makeSampleRecord(rideID: "ride-order", timestamp: 1_000)
        )
        try await repository.insert(
            makeSampleRecord(rideID: "ride-order", timestamp: 2_000)
        )

        let fetched = try await repository.fetchUnsynced(rideID: "ride-order")
        #expect(fetched.count == 3)
        #expect(fetched[0].timestamp == 1_000)
        #expect(fetched[1].timestamp == 2_000)
        #expect(fetched[2].timestamp == 3_000)
    }
}
