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

    func driverOffers() async throws -> DriverRideOffersDTO {
        try requireDriver()

        let rides = try await Ride.query(on: req.db)
            .filter(\.$status == .requested)
            .filter(\.$driver.$id == nil)
            .sort(\.$requestedAt)
            .limit(5)
            .all()

        var offers: [DriverRideOfferDTO] = []
        for ride in rides {
            let passenger = try await User.find(ride.$passenger.id, on: req.db)
            offers.append(try DriverRideOfferDTO(ride: ride, passenger: passenger))
        }

        return DriverRideOffersDTO(offers: offers)
    }

    func driverAccept(rideID: UUID) async throws -> DriverRideOfferDTO {
        try requireDriver()
        let driverID = try req.authenticatedUserID

        guard let ride = try await Ride.find(rideID, on: req.db) else {
            throw Abort(.notFound, reason: "Ride not found")
        }

        guard ride.status == .requested || ride.status == .matched else {
            throw Abort(.conflict, reason: "Ride is no longer available")
        }

        if let assignedDriverID = ride.$driver.id, assignedDriverID != driverID {
            throw Abort(.conflict, reason: "Ride already assigned to another driver")
        }

        ride.$driver.id = driverID
        ride.status = .driverAccepted
        ride.fareTenge = ride.fareTenge ?? 1850
        try await ride.save(on: req.db)
        try await broadcastStatus(for: ride)

        let passenger = try await User.find(ride.$passenger.id, on: req.db)
        return try DriverRideOfferDTO(ride: ride, passenger: passenger)
    }

    func driverUpdate(rideID: UUID, status: Ride.RideStatus) async throws -> DriverRideOfferDTO {
        try requireDriver()

        guard let ride = try await Ride.find(rideID, on: req.db) else {
            throw Abort(.notFound, reason: "Ride not found")
        }

        try authorizeDriverAccess(to: ride)
        try validateDriverTransition(from: ride.status, to: status)

        ride.status = status
        try await ride.save(on: req.db)
        try await broadcastStatus(for: ride)

        let passenger = try await User.find(ride.$passenger.id, on: req.db)
        return try DriverRideOfferDTO(ride: ride, passenger: passenger)
    }

    private func authorizeAccess(to ride: Ride) throws {
        let userID = try req.authenticatedUserID
        if ride.$passenger.id == userID || ride.$driver.id == userID {
            return
        }

        throw Abort(.forbidden, reason: "Ride does not belong to authenticated user")
    }

    private func requireDriver() throws {
        guard try req.authenticatedUserRole == User.UserRole.driver.rawValue else {
            throw Abort(.forbidden, reason: "Only drivers can access driver rides")
        }
    }

    private func authorizeDriverAccess(to ride: Ride) throws {
        let driverID = try req.authenticatedUserID
        guard ride.$driver.id == driverID else {
            throw Abort(.forbidden, reason: "Ride is not assigned to authenticated driver")
        }
    }

    private func validateDriverTransition(from current: Ride.RideStatus, to next: Ride.RideStatus) throws {
        let allowed: Bool
        switch (current, next) {
        case (.driverAccepted, .passengerWait),
             (.driverArriving, .passengerWait),
             (.passengerWait, .inProgress),
             (.inProgress, .completed):
            allowed = true
        default:
            allowed = current == next
        }

        guard allowed else {
            throw Abort(.conflict, reason: "Invalid driver ride transition")
        }
    }

    private func broadcastStatus(for ride: Ride) async throws {
        let driver = try await ride.$driver.get(on: req.db)
        let driverProfile: DriverProfile?
        if let driverID = ride.$driver.id {
            driverProfile = try await DriverProfile.query(on: req.db)
                .filter(\.$user.$id == driverID)
                .first()
        } else {
            driverProfile = nil
        }
        let payload = try RideStatusBroadcastDTO(
            ride: ride,
            driverProfile: driverProfile,
            driver: driver
        )
        let data = try JSONEncoder().encode(payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Could not encode ride status event")
        }

        await req.application.wsHub.broadcast(
            to: "ride/\(try ride.requireID().uuidString)",
            text: text
        )
    }
}
