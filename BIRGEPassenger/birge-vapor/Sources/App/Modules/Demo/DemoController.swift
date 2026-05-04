import Vapor

struct DemoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let demo = routes.grouped(JWTMiddleware()).grouped("demo")
        demo.get("state", use: state)
        demo.post("seed", use: seed)
        demo.post("reset", use: reset)
    }

    func state(req: Request) async throws -> DemoStateDTO {
        try await DemoService(req: req).state()
    }

    func seed(req: Request) async throws -> DemoStateDTO {
        try await DemoService(req: req).seed()
    }

    func reset(req: Request) async throws -> DemoStateDTO {
        try await DemoService(req: req).reset()
    }
}
