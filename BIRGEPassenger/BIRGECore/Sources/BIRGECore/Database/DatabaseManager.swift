//
//  DatabaseManager.swift
//  BIRGECore
//
//  Created for BIRGE ride-hailing app.
//

import Foundation
import GRDB

/// Thread-safe database manager using GRDB with WAL mode.
///
/// Per RULES.md:
/// - `actor` for stateful services — never `@MainActor`
/// - DatabaseQueue on background queue, never main
///
/// Per iOS_Agent_Context.md:
/// - WAL mode for thread-safe background bulk inserts
/// - GPS coordinates ALWAYS written to GRDB even without network
public actor DatabaseManager {

    // MARK: - Singleton

    /// Shared instance for production use.
    /// Initialized lazily on first access.
    public static let shared = DatabaseManager()

    // MARK: - Properties

    /// The underlying GRDB database queue.
    /// `nonisolated(unsafe)` is acceptable here because `DatabaseQueue` is
    /// internally thread-safe and we only assign it once during `setup()`.
    nonisolated(unsafe) private var _dbQueue: DatabaseQueue?

    /// Public accessor that ensures the database has been set up.
    public var dbQueue: DatabaseQueue {
        get throws {
            guard let queue = _dbQueue else {
                throw DatabaseManagerError.notInitialized
            }
            return queue
        }
    }

    // MARK: - Initialization

    private init() {}

    /// Initialize the database manager with a custom `DatabaseQueue`.
    /// Used for testing with in-memory databases.
    public init(dbQueue: DatabaseQueue) {
        self._dbQueue = dbQueue
    }

    // MARK: - Setup

    /// Set up the database at the default application support path.
    /// Must be called once at app launch before any database operations.
    public func setup() throws {
        guard _dbQueue == nil else { return }

        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let dbDirectoryURL = appSupportURL.appendingPathComponent(
            "BIRGEDatabase",
            isDirectory: true
        )

        try fileManager.createDirectory(
            at: dbDirectoryURL,
            withIntermediateDirectories: true
        )

        let dbPath = dbDirectoryURL
            .appendingPathComponent("birge.sqlite")
            .path

        // WAL mode: thread-safe concurrent reads/writes
        var config = Configuration()
        config.journalMode = .wal

        let queue = try DatabaseQueue(path: dbPath, configuration: config)
        try Self.runMigrations(on: queue)
        self._dbQueue = queue
    }

    // MARK: - Migrations

    /// Run all database migrations using GRDB's `DatabaseMigrator`.
    /// Migrations are versioned and idempotent.
    private static func runMigrations(on dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        // v1: GPS location cache table
        // Schema matches iOS_Agent_Context.md GRDB Schema section exactly
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
    }
}

// MARK: - Errors

public enum DatabaseManagerError: Error, Sendable {
    case notInitialized
}
