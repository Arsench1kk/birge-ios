import Vapor

struct CommutePlansController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let plans = routes.grouped("commute", "plans")
        let auth = plans.grouped(JWTMiddleware())

        auth.get("me", use: current)
        auth.post(use: create)
        auth.post("cancel", use: cancel)
    }

    @Sendable
    func current(req: Request) async throws -> CommutePlansDTO.PlanStatusResponse {
        try await CommutePlansService(req: req).currentPlan()
    }

    @Sendable
    func create(req: Request) async throws -> CommutePlansDTO.PlanResponse {
        let dto = try req.content.decode(CommutePlansDTO.CreatePlanRequest.self)
        return try await CommutePlansService(req: req).create(dto)
    }

    @Sendable
    func cancel(req: Request) async throws -> CommutePlansDTO.PlanStatusResponse {
        try await CommutePlansService(req: req).cancel()
    }
}
