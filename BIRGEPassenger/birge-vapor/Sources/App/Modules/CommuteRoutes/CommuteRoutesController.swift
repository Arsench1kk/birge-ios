import Vapor

struct CommuteRoutesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let commute = routes.grouped("commute", "routes")
        let auth = commute.grouped(JWTMiddleware())

        auth.get(use: list)
        auth.post(use: create)
        auth.delete(":routeID", use: delete)
    }

    @Sendable
    func list(req: Request) async throws -> CommuteRoutesDTO.RoutesListResponse {
        try await CommuteRoutesService(req: req).list()
    }

    @Sendable
    func create(req: Request) async throws -> CommuteRoutesDTO.RouteResponse {
        let dto = try req.content.decode(CommuteRoutesDTO.CreateRouteRequest.self)
        return try await CommuteRoutesService(req: req).create(dto)
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let routeID = req.parameters.get("routeID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid route ID")
        }
        return try await CommuteRoutesService(req: req).delete(routeID: routeID)
    }
}
