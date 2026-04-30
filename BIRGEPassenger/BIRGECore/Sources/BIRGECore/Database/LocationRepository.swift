//
//  LocationRepository.swift
//  BIRGECore
//
//  Created for BIRGE ride-hailing app.
//

import Foundation
import GRDB

/// Repository for GPS location records in GRDB.
///
/// Per RULES.md:
/// - `actor` for stateful services — never `@MainActor`
/// - All operations execute on background DatabaseQueue
///
/// Per iOS_Agent_Context.md:
/// - Bulk insert: 100–200 records at a time
/// - Background queue always
/// - GPS coordinates ALWAYS written even without network
public actor LocationRepository {

    // MARK: - Properties

    private let dbQueue: DatabaseQueue

    // MARK: - Initialization

    /// Initialize with a `DatabaseQueue`.
    /// - Parameter dbQueue: The database queue (production or in-memory for tests).
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Convenience initializer using the shared `DatabaseManager`.
    public init(databaseManager: DatabaseManager) async throws {
        self.dbQueue = try await databaseManager.dbQueue
    }

    // MARK: - Insert

    /// Insert a single location record.
    /// - Parameter record: The location record to insert.
    public func insert(_ record: LocationRecord) async throws {
        var mutableRecord = record
        try await dbQueue.write { db in
            try mutableRecord.insert(db)
        }
    }

    /// Bulk insert an array of location records in a single transaction.
    ///
    /// Per iOS_Agent_Context.md: "Bulk insert: 100–200 записей за раз.
    /// Background queue всегда."
    ///
    /// - Parameter records: The location records to insert.
    public func insertBatch(_ records: [LocationRecord]) async throws {
        try await dbQueue.write { db in
            for var record in records {
                try record.insert(db)
            }
        }
    }

    // MARK: - Fetch

    /// Fetch all unsynced location records for a specific ride.
    /// - Parameter rideID: The ride identifier.
    /// - Returns: An array of unsynced `LocationRecord` values, ordered by timestamp.
    public func fetchUnsynced(rideID: String) async throws -> [LocationRecord] {
        try await dbQueue.read { db in
            try LocationRecord
                .filter(LocationRecord.Columns.rideID == rideID)
                .filter(LocationRecord.Columns.synced == false)
                .order(LocationRecord.Columns.timestamp.asc)
                .fetchAll(db)
        }
    }

    // MARK: - Update

    /// Mark a batch of location records as synced.
    /// - Parameter ids: The primary key IDs of records to mark as synced.
    public func markSynced(_ ids: [Int64]) async throws {
        guard !ids.isEmpty else { return }
        try await dbQueue.write { db in
            try LocationRecord
                .filter(ids.contains(LocationRecord.Columns.id))
                .updateAll(db, LocationRecord.Columns.synced.set(to: true))
        }
    }
}
