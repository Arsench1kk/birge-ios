import Fluent
import Vapor

struct CommuteRoutesService {
    let req: Request

    func list() async throws -> CommuteRoutesDTO.RoutesListResponse {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can manage commute routes")
        }

        let userID = try req.authenticatedUserID
        let routes = try await RecurringRoute.query(on: req.db)
            .filter(\.$passenger.$id == userID)
            .filter(\.$isActive == true)
            .sort(\.$createdAt, .descending)
            .all()

        return try CommuteRoutesDTO.RoutesListResponse(
            routes: routes.map(CommuteRoutesDTO.RouteResponse.init)
        )
    }

    func create(_ dto: CommuteRoutesDTO.CreateRouteRequest) async throws -> CommuteRoutesDTO.RouteResponse {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can create commute routes")
        }

        let userID = try req.authenticatedUserID
        let route = RecurringRoute(
            passengerID: userID,
            originName: dto.originName,
            originLat: dto.originLat,
            originLng: dto.originLng,
            destinationName: dto.destinationName,
            destinationLat: dto.destinationLat,
            destinationLng: dto.destinationLng,
            weekdays: dto.weekdays,
            departureWindow: dto.departureWindow
        )

        try await route.save(on: req.db)
        return try CommuteRoutesDTO.RouteResponse(route: route)
    }

    func delete(routeID: UUID) async throws -> HTTPStatus {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can manage commute routes")
        }

        let userID = try req.authenticatedUserID
        guard let route = try await RecurringRoute.query(on: req.db)
            .filter(\.$id == routeID)
            .filter(\.$passenger.$id == userID)
            .first() else {
            throw Abort(.notFound, reason: "Route not found")
        }

        route.isActive = false
        try await route.save(on: req.db)
        return .noContent
    }
}
