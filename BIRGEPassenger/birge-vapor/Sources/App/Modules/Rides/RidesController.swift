import Vapor

struct RidesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let rides = routes.grouped(JWTMiddleware()).grouped("rides")
        rides.post(use: create)
        rides.get(":rideID", use: get)
        rides.post(":rideID", "cancel", use: cancel)
    }

    func create(req: Request) async throws -> RideResponseDTO {
        let dto = try req.content.decode(CreateRideDTO.self)
        return try await RidesService(req: req).create(dto: dto)
    }

    func get(req: Request) async throws -> RideResponseDTO {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        return try await RidesService(req: req).get(rideID: rideID)
    }

    func cancel(req: Request) async throws -> RideResponseDTO {
        let rideID = try req.parameters.require("rideID", as: UUID.self)
        return try await RidesService(req: req).cancel(rideID: rideID)
    }
}
