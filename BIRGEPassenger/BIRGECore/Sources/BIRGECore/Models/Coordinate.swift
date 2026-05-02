//
//  Coordinate.swift
//  BIRGECore
//
//  Equatable, Sendable, Codable wrapper for CLLocationCoordinate2D.
//  IOS-016 — RideFeature State Machine
//
//  CLLocationCoordinate2D does not conform to Equatable by default.
//  This wrapper is used in TCA State (which requires Equatable) and
//  in WebSocket event payloads (which require Codable + Sendable).
//

import CoreLocation
import Foundation

/// A `Sendable`, `Equatable`, `Codable` wrapper for geographic coordinates.
///
/// Used throughout TCA State and WebSocket event payloads where
/// `CLLocationCoordinate2D` cannot be used directly (it is not
/// `Equatable`, `Codable`, or `Sendable`).
///
/// Usage:
/// ```swift
/// let coord = Coordinate(latitude: 43.238, longitude: 76.945)
/// let clCoord = coord.clCoordinate // CLLocationCoordinate2D
/// ```
public struct Coordinate: Equatable, Sendable, Codable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Initialize from a `CLLocationCoordinate2D`.
    public init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    /// Convert to `CLLocationCoordinate2D` for MapKit usage.
    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
