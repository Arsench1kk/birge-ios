import Vapor

struct DriversController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let drivers = routes.grouped(JWTMiddleware()).grouped("drivers")
        drivers.get("me", use: me)
        drivers.put("me", use: updateMe)
        drivers.post("me", use: updateMe)
        drivers.get("corridors", "today", use: todayCorridors)
    }

    func me(req: Request) async throws -> DriverProfileDTO {
        try await DriversService(req: req).me()
    }

    func updateMe(req: Request) async throws -> DriverProfileDTO {
        let dto = try req.content.decode(UpdateDriverProfileDTO.self)
        return try await DriversService(req: req).updateMe(dto: dto)
    }

    func todayCorridors(req: Request) async throws -> DriverTodayCorridorsDTO {
        try await DriversService(req: req).todayCorridors()
    }
}
