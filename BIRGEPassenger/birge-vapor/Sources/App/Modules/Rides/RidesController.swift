import Vapor

struct RidesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let rides = routes.grouped(JWTMiddleware()).grouped("rides")
        rides.post(use: create)
        rides.get(":rideID", use: get)
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
}
