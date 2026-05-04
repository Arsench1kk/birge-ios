import Vapor

struct LocationsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let locations = routes.grouped(JWTMiddleware()).grouped("locations")
        locations.post("bulk", use: uploadBulk)
    }

    func uploadBulk(req: Request) async throws -> LocationBulkResponseDTO {
        let dto = try req.content.decode(LocationBulkDTO.self)
        return try await LocationsService(req: req).uploadBulk(dto: dto)
    }
}
