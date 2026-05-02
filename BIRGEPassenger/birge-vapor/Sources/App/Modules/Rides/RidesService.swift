import Fluent
import Vapor

struct RidesService {
    let req: Request

    func create(dto: CreateRideDTO) async throws -> RideDTO {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can request rides")
        }

        guard CreateRideDTO.allowedTiers.contains(dto.tier) else {
            throw Abort(.badRequest, reason: "Unsupported ride tier")
        }

        let ride = Ride(
            passengerID: try req.authenticatedUserID,
            status: .requested,
            originLat: dto.originLat,
            originLng: dto.originLng,
            destLat: dto.destinationLat,
            destLng: dto.destinationLng,
            tier: dto.tier
        )

        try await ride.save(on: req.db)
        return try RideDTO(ride: ride)
    }

    func get(rideID: UUID) async throws -> RideDTO {
        guard let ride = try await Ride.find(rideID, on: req.db) else {
            throw Abort(.notFound, reason: "Ride not found")
        }

        try authorizeAccess(to: ride)
        return try RideDTO(ride: ride)
    }

    func cancel(rideID: UUID) async throws -> RideDTO {
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

        return try RideDTO(ride: ride)
    }

    private func authorizeAccess(to ride: Ride) throws {
        let userID = try req.authenticatedUserID
        if ride.$passenger.id == userID || ride.$driver.id == userID {
            return
        }

        throw Abort(.forbidden, reason: "Ride does not belong to authenticated user")
    }
}
