import Vapor

struct RidesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let rides = routes.grouped(JWTMiddleware()).grouped("rides")
        rides.post(use: create)
        rides.get("driver", "offers", use: driverOffers)
        rides.get(":rideID", use: get)
        rides.post(":rideID", "driver", "accept", use: driverAccept)
        rides.post(":rideID", "driver", "decline", use: driverDecline)
        rides.post(":rideID", "driver", "arrived", use: driverArrived)
        rides.post(":rideID", "driver", "start", use: driverStart)
        rides.post(":rideID", "driver", "complete", use: driverComplete)
        rides.put(":rideID", "cancel", use: cancel)
        rides.patch(":rideID", "cancel", use: cancel)
        rides.post(":rideID", "cancel", use: cancel)
    }

    func create(req: Request) async throws -> Response {
        let dto = try req.content.decode(CreateRideDTO.self)
        let ride = try await RidesService(req: req).create(dto: dto)
        let response = Response(status: .created)
        try response.content.encode(ride)
        return response
    }

    func get(req: Request) async throws -> RideDTO {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        return try await RidesService(req: req).get(rideID: rideID)
    }

    func cancel(req: Request) async throws -> RideDTO {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        return try await RidesService(req: req).cancel(rideID: rideID)
    }

    func driverOffers(req: Request) async throws -> DriverRideOffersDTO {
        try await RidesService(req: req).driverOffers()
    }

    func driverAccept(req: Request) async throws -> DriverRideOfferDTO {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        return try await RidesService(req: req).driverAccept(rideID: rideID)
    }

    func driverDecline(req: Request) async throws -> HTTPStatus {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        try await RidesService(req: req).driverDecline(rideID: rideID)
        return .noContent
    }

    func driverArrived(req: Request) async throws -> DriverRideOfferDTO {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        return try await RidesService(req: req).driverUpdate(rideID: rideID, status: .passengerWait)
    }

    func driverStart(req: Request) async throws -> DriverRideOfferDTO {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        return try await RidesService(req: req).driverUpdate(rideID: rideID, status: .inProgress)
    }

    func driverComplete(req: Request) async throws -> DriverRideOfferDTO {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        return try await RidesService(req: req).driverUpdate(rideID: rideID, status: .completed)
    }
}
