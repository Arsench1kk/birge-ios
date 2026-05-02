//
//  LocationSyncService.swift
//  BIRGECore
//
//  Batch sync utility for unsynced GPS records.
//  IOS-015 — LocationClient TCA Dependency
//
//  Architecture ref: iOS_Agent_Context.md — "Bulk insert: 100–200 records"
//                    iOS_Architecture.md Section 3 — Network Drop → Reconnect Flow
//
//  Design:
//  - Stateless enum (no instances)
//  - Fetches unsynced → batches of 200 → upload → markSynced
//  - Idempotent: safe to call multiple times
//  - Upload closure is injectable for testing
//

import Foundation

/// Stateless utility for bulk-syncing unsynced GPS records from GRDB
/// to the backend.
///
/// Per iOS_Agent_Context.md:
/// - Bulk insert: 100–200 records at a time
/// - Background queue always
///
/// Per iOS_Architecture.md Section 3:
/// - Network restores → background GRDB DatabaseQueue executes bulk INSERT
/// - 100–200 cached records → Vapor backend in one batch
///
/// Usage:
/// ```swift
/// try await LocationSyncService.syncIfNeeded(
///     rideID: "ride-123",
///     repository: repository,
///     uploadBatch: { records in
///         try await apiClient.postLocationsBulk(records)
///     }
/// )
/// ```
public enum LocationSyncService {

    /// Maximum number of records per upload batch.
    /// Per iOS_Agent_Context.md: 100–200 records at a time.
    public static let batchSize = 200

    /// Fetches unsynced records from GRDB, batches them, uploads each
    /// batch via the provided closure, then marks them as synced.
    ///
    /// - Parameters:
    ///   - rideID: The ride identifier to fetch unsynced records for.
    ///   - repository: The GRDB `LocationRepository` to read/write from.
    ///   - uploadBatch: A closure that sends a batch of records to the backend.
    ///     Injected to allow mocking in tests and future API client wiring.
    ///
    /// - Throws: Rethrows errors from `uploadBatch`. Already-synced batches
    ///   remain marked even if a later batch fails.
    ///
    /// - Note: Idempotent — calling with zero unsynced records returns immediately.
    public static func syncIfNeeded(
        rideID: String,
        repository: LocationRepository,
        uploadBatch: @Sendable ([LocationRecord]) async throws -> Void
    ) async throws {
        // Fetch all unsynced records for this ride
        let unsyncedRecords = try await repository.fetchUnsynced(rideID: rideID)

        // Nothing to sync — return immediately
        guard !unsyncedRecords.isEmpty else { return }

        // Split into batches of `batchSize`
        let batches = stride(from: 0, to: unsyncedRecords.count, by: batchSize)
            .map { startIndex in
                let endIndex = min(startIndex + batchSize, unsyncedRecords.count)
                return Array(unsyncedRecords[startIndex..<endIndex])
            }

        // Upload each batch, then mark as synced
        for batch in batches {
            // Upload to backend
            try await uploadBatch(batch)

            // Extract IDs for marking as synced
            let ids = batch.compactMap(\.id)
            guard !ids.isEmpty else { continue }

            // Mark synced in GRDB
            try await repository.markSynced(ids)
        }
    }
}
