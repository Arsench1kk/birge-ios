import Vapor

struct SubscriptionsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let subscriptions = routes.grouped(JWTMiddleware()).grouped("subscriptions")
        subscriptions.get(use: overview)
        subscriptions.post("activate", use: activate)
    }

    func overview(req: Request) async throws -> SubscriptionOverviewDTO {
        try await SubscriptionsService(req: req).overview()
    }

    func activate(req: Request) async throws -> ActivateSubscriptionResponseDTO {
        let dto = try req.content.decode(ActivateSubscriptionRequestDTO.self)
        return try await SubscriptionsService(req: req).activate(dto)
    }
}
