import Fluent
import Vapor

struct RidesService {
    let req: Request

    func create(dto: CreateRideDTO) async throws -> RideResponseDTO {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can request rides")
        }

        let ride = Ride(
            passengerID: try req.authenticatedUserID,
            status: .requested,
            originLat: dto.origin.lat,
            originLng: dto.origin.lng,
            destLat: dto.destination.lat,
            destLng: dto.destination.lng
        )

        try await ride.save(on: req.db)
        return try RideResponseDTO(ride: ride)
    }

    func get(rideID: UUID) async throws -> RideResponseDTO {
        guard let ride = try await Ride.find(rideID, on: req.db) else {
            throw Abort(.notFound, reason: "Ride not found")
        }

        try authorizeAccess(to: ride)
        return try RideResponseDTO(ride: ride)
    }

    func cancel(rideID: UUID) async throws -> RideResponseDTO {
        guard let ride = try await Ride.find(rideID, on: req.db) else {
            throw Abort(.notFound, reason: "Ride not found")
        }

        try authorizeAccess(to: ride)

        guard ride.status != .completed else {
            throw Abort(.conflict, reason: "Completed rides cannot be cancelled")
        }

        if ride.status != .cancelled {
            ride.status = .cancelled
            try await ride.save(on: req.db)
        }

        return try RideResponseDTO(ride: ride)
    }

    private func authorizeAccess(to ride: Ride) throws {
        let userID = try req.authenticatedUserID
        if ride.$passenger.id == userID || ride.$driver.id == userID {
            return
        }

        throw Abort(.forbidden, reason: "Ride does not belong to authenticated user")
    }
}
