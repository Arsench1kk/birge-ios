//
//  LocationRecord.swift
//  BIRGECore
//
//  Created for BIRGE ride-hailing app.
//

import Foundation
import GRDB

/// GPS location record stored in GRDB for offline caching.
///
/// Schema matches iOS_Agent_Context.md exactly:
/// ```sql
/// CREATE TABLE location_records (
///     id INTEGER PRIMARY KEY AUTOINCREMENT,
///     ride_id TEXT NOT NULL,
///     latitude REAL NOT NULL,
///     longitude REAL NOT NULL,
///     timestamp REAL NOT NULL,
///     accuracy REAL,
///     synced INTEGER NOT NULL DEFAULT 0
/// );
/// ```
///
/// Business rule: GPS coordinates are ALWAYS written to GRDB
/// even without network connectivity.
public struct LocationRecord: Codable, Sendable, Equatable {

    /// Auto-incremented primary key. `nil` for new records before insertion.
    public var id: Int64?

    /// The ride this location belongs to.
    public var rideID: String

    /// WGS-84 latitude in degrees.
    public var latitude: Double

    /// WGS-84 longitude in degrees.
    public var longitude: Double

    /// Unix timestamp (seconds since epoch).
    public var timestamp: Double

    /// Location accuracy in meters. `nil` if unavailable.
    public var accuracy: Double?

    /// Whether this record has been synced to the backend.
    /// Stored as INTEGER (0/1) in SQLite.
    public var synced: Bool

    // MARK: - Initialization

    public init(
        id: Int64? = nil,
        rideID: String,
        latitude: Double,
        longitude: Double,
        timestamp: Double,
        accuracy: Double? = nil,
        synced: Bool = false
    ) {
        self.id = id
        self.rideID = rideID
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.accuracy = accuracy
        self.synced = synced
    }
}

// MARK: - GRDB Conformances

extension LocationRecord: FetchableRecord, PersistableRecord {

    /// Map to the SQLite table name.
    public static let databaseTableName = "location_records"

    /// Column definitions for type-safe queries.
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let rideID = Column(CodingKeys.rideID)
        public static let latitude = Column(CodingKeys.latitude)
        public static let longitude = Column(CodingKeys.longitude)
        public static let timestamp = Column(CodingKeys.timestamp)
        public static let accuracy = Column(CodingKeys.accuracy)
        public static let synced = Column(CodingKeys.synced)
    }

    /// Map Swift property names to SQLite column names.
    enum CodingKeys: String, CodingKey {
        case id
        case rideID = "ride_id"
        case latitude
        case longitude
        case timestamp
        case accuracy
        case synced
    }

    /// Persist the record, receiving the auto-incremented ID after insert.
    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
