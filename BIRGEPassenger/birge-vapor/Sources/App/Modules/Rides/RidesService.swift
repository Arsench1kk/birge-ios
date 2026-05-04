import Fluent
import SQLKit
import Vapor

struct RidesService {
    let req: Request
    private static let offerTTL = DriverOfferPolicy.offerTTL

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
            originName: normalized(dto.originName),
            destinationName: normalized(dto.destinationName),
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
        let driverID = try req.authenticatedUserID
        let cutoff = Date().addingTimeInterval(-Self.offerTTL)

        let rides = try await Ride.query(on: req.db)
            .filter(\.$status == .requested)
            .filter(\.$driver.$id == nil)
            .filter(\.$requestedAt >= cutoff)
            .sort(\.$requestedAt)
            .limit(20)
            .all()

        var offers: [DriverRideOfferDTO] = []
        for ride in rides {
            let rideID = try ride.requireID()
            let wasDeclined = try await DriverRideDecision.query(on: req.db)
                .filter(\.$ride.$id == rideID)
                .filter(\.$driver.$id == driverID)
                .filter(\.$decision == .declined)
                .first() != nil
            if !DriverOfferPolicy.isVisibleToDriver(
                status: ride.status,
                assignedDriverID: ride.$driver.id,
                requestedAt: ride.requestedAt,
                wasDeclined: wasDeclined
            ) {
                continue
            }

            let passenger = try await User.find(ride.$passenger.id, on: req.db)
            offers.append(try DriverRideOfferDTO(ride: ride, passenger: passenger))
            if offers.count == 5 {
                break
            }
        }

        return DriverRideOffersDTO(offers: offers)
    }

    func driverAccept(rideID: UUID) async throws -> DriverRideOfferDTO {
        try requireDriver()
        let driverID = try req.authenticatedUserID

        let ride = try await req.db.transaction { database in
            if let sql = database as? SQLDatabase {
                try await sql.raw(
                    "SELECT id FROM \(ident: Ride.schema) WHERE id = \(bind: rideID) FOR UPDATE"
                )
                .run()
            }

            guard let ride = try await Ride.find(rideID, on: database) else {
                throw Abort(.notFound, reason: "Ride not found")
            }

            guard ride.status == .requested || ride.status == .matched else {
                throw Abort(.conflict, reason: "Ride is no longer available")
            }

            if !DriverOfferPolicy.isFresh(requestedAt: ride.requestedAt) {
                throw Abort(.conflict, reason: "Ride request expired")
            }

            if let assignedDriverID = ride.$driver.id, assignedDriverID != driverID {
                throw Abort(.conflict, reason: "Ride already assigned to another driver")
            }

            if let decision = try await DriverRideDecision.query(on: database)
                .filter(\.$ride.$id == rideID)
                .filter(\.$driver.$id == driverID)
                .first() {
                switch decision.decision {
                case .accepted:
                    break
                case .declined:
                    throw Abort(.conflict, reason: "Ride was declined by this driver")
                }
            } else {
                let decision = DriverRideDecision(
                    rideID: rideID,
                    driverID: driverID,
                    decision: .accepted
                )
                try await decision.save(on: database)
            }

            ride.$driver.id = driverID
            ride.status = .driverAccepted
            ride.fareTenge = ride.fareTenge ?? 1850
            try await ride.save(on: database)
            return ride
        }
        try await broadcastStatus(for: ride)

        let passenger = try await User.find(ride.$passenger.id, on: req.db)
        return try DriverRideOfferDTO(ride: ride, passenger: passenger)
    }

    func driverDecline(rideID: UUID) async throws {
        try requireDriver()
        let driverID = try req.authenticatedUserID

        guard let ride = try await Ride.find(rideID, on: req.db) else {
            throw Abort(.notFound, reason: "Ride not found")
        }

        guard ride.status == .requested, ride.$driver.id == nil else {
            throw Abort(.conflict, reason: "Ride is no longer available")
        }

        if let existing = try await DriverRideDecision.query(on: req.db)
            .filter(\.$ride.$id == rideID)
            .filter(\.$driver.$id == driverID)
            .first() {
            if existing.decision == .accepted {
                throw Abort(.conflict, reason: "Ride already accepted by this driver")
            }
            return
        }

        let decision = DriverRideDecision(
            rideID: rideID,
            driverID: driverID,
            decision: .declined
        )
        try await decision.save(on: req.db)
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

    private func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == true ? nil : trimmed
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

enum DriverOfferPolicy {
    static let offerTTL: TimeInterval = 15 * 60

    static func isFresh(requestedAt: Date?, now: Date = Date()) -> Bool {
        guard let requestedAt else { return true }
        return requestedAt >= now.addingTimeInterval(-offerTTL)
    }

    static func isVisibleToDriver(
        status: Ride.RideStatus,
        assignedDriverID: UUID?,
        requestedAt: Date?,
        wasDeclined: Bool,
        now: Date = Date()
    ) -> Bool {
        status == .requested &&
            assignedDriverID == nil &&
            !wasDeclined &&
            isFresh(requestedAt: requestedAt, now: now)
    }
}
