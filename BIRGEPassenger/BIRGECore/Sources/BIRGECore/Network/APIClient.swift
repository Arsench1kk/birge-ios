//
//  APIClient.swift
//  BIRGECore
//
//  Stub TCA dependency for REST API calls.
//  IOS-016 — RideFeature State Machine
//
//  This is a STUB — liveValue uses XCTUnimplemented closures.
//  The real URLSession-backed implementation comes in IOS-017.
//
//  Only the endpoints needed by RideFeature are defined here:
//  - GET  /rides/:id       → fetchRide
//  - POST /rides/:id/cancel → cancelRide
//

import ComposableArchitecture
import Foundation

// MARK: - Ride Response

/// Response from `GET /rides/:id`.
/// Contains the current server-side state of a ride.
public struct RideResponse: Equatable, Sendable {
    public let rideId: String
    public let status: String
    public let driverName: String?
    public let driverRating: Double?
    public let driverVehicle: String?
    public let driverPlate: String?
    public let etaSeconds: Int?
    public let verificationCode: String?
    public let pickupLatitude: Double?
    public let pickupLongitude: Double?

    public init(
        rideId: String,
        status: String,
        driverName: String? = nil,
        driverRating: Double? = nil,
        driverVehicle: String? = nil,
        driverPlate: String? = nil,
        etaSeconds: Int? = nil,
        verificationCode: String? = nil,
        pickupLatitude: Double? = nil,
        pickupLongitude: Double? = nil
    ) {
        self.rideId = rideId
        self.status = status
        self.driverName = driverName
        self.driverRating = driverRating
        self.driverVehicle = driverVehicle
        self.driverPlate = driverPlate
        self.etaSeconds = etaSeconds
        self.verificationCode = verificationCode
        self.pickupLatitude = pickupLatitude
        self.pickupLongitude = pickupLongitude
    }
}

// MARK: - API Client

/// TCA dependency for REST API calls.
///
/// Usage in a Reducer:
/// ```swift
/// @Dependency(\.apiClient) var apiClient
/// ```
///
/// Never instantiate directly — always inject via `@Dependency`.
public struct APIClient: Sendable {
    /// Fetch the current state of a ride from the server.
    /// Used on WebSocket reconnect to recover missed state transitions.
    ///
    /// `GET /api/v1/rides/:id`
    public var fetchRide: @Sendable (_ rideID: String) async throws -> RideResponse

    /// Cancel an active ride with a reason.
    ///
    /// `POST /api/v1/rides/:id/cancel`
    public var cancelRide: @Sendable (_ rideID: String, _ reason: String) async throws -> Void

    public init(
        fetchRide: @escaping @Sendable (_ rideID: String) async throws -> RideResponse,
        cancelRide: @escaping @Sendable (_ rideID: String, _ reason: String) async throws -> Void
    ) {
        self.fetchRide = fetchRide
        self.cancelRide = cancelRide
    }
}

// MARK: - DependencyKey

extension APIClient: DependencyKey {
    /// Stub live value — will be replaced with real URLSession
    /// implementation in IOS-017.
    public static var liveValue: APIClient {
        APIClient(
            fetchRide: { _ in
                fatalError("[APIClient] liveValue.fetchRide not implemented — see IOS-017")
            },
            cancelRide: { _, _ in
                fatalError("[APIClient] liveValue.cancelRide not implemented — see IOS-017")
            }
        )
    }

    /// Controllable mock for unit tests.
    public static var testValue: APIClient {
        APIClient(
            fetchRide: { _ in
                RideResponse(rideId: "test", status: "requested")
            },
            cancelRide: { _, _ in }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    /// Access the `APIClient` dependency in a Reducer.
    ///
    /// ```swift
    /// @Dependency(\.apiClient) var apiClient
    /// ```
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
