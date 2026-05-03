import Vapor

struct PaymentsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let payments = routes.grouped("payments")
        payments.grouped(JWTMiddleware()).post("kaspi", "checkout", use: createKaspiCheckout)
        payments.post("kaspi", "webhook", use: handleKaspiWebhook)
    }

    func createKaspiCheckout(req: Request) async throws -> KaspiCheckoutResponseDTO {
        let dto = try req.content.decode(KaspiCheckoutRequestDTO.self)
        return try await PaymentsService(req: req).createKaspiCheckout(dto)
    }

    func handleKaspiWebhook(req: Request) async throws -> KaspiWebhookResponseDTO {
        let dto = try req.content.decode(KaspiWebhookDTO.self)
        return try await PaymentsService(req: req).handleKaspiWebhook(dto)
    }
}
