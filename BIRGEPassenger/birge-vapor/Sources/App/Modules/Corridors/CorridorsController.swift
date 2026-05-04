import Vapor

struct CorridorsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let corridors = routes.grouped(JWTMiddleware()).grouped("corridors")
        corridors.get(use: list)
        corridors.get("bookings", use: bookings)
        corridors.post(":corridorID", "book", use: book)
    }

    func list(req: Request) async throws -> CorridorListDTO {
        try await CorridorsService(req: req).list()
    }

    func book(req: Request) async throws -> CorridorBookingDTO {
        let corridorID = try req.parameters.require("corridorID", as: UUID.self)
        return try await CorridorsService(req: req).book(corridorID: corridorID)
    }

    func bookings(req: Request) async throws -> CorridorBookingsListDTO {
        try await CorridorsService(req: req).bookings()
    }
}
