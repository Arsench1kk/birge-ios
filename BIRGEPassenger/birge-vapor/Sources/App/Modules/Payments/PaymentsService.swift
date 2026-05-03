import Fluent
import Vapor

struct PaymentsService {
    let req: Request

    func createKaspiCheckout(_ dto: KaspiCheckoutRequestDTO) async throws -> KaspiCheckoutResponseDTO {
        guard dto.amountTenge > 0 else {
            throw Abort(.badRequest, reason: "Payment amount must be positive")
        }

        let userID = try req.authenticatedUserID
        let paymentID = UUID()
        let deepLink = "kaspi://pay?service=birge&payment_id=\(paymentID.uuidString)&amount=\(dto.amountTenge)"
        let metadata = "plan_id=\(dto.planID ?? "none")"

        let event = PaymentEvent(
            userID: userID,
            eventID: "checkout:\(paymentID.uuidString)",
            paymentID: paymentID,
            provider: "kaspi",
            purpose: dto.purpose,
            amountTenge: dto.amountTenge,
            status: "checkout_created",
            checkoutURL: deepLink,
            metadataJSON: metadata
        )
        try await event.save(on: req.db)

        return KaspiCheckoutResponseDTO(
            paymentID: paymentID,
            provider: "kaspi",
            status: "checkout_created",
            amountTenge: dto.amountTenge,
            kaspiDeepLink: deepLink,
            message: "Open Kaspi to complete payment"
        )
    }

    func handleKaspiWebhook(_ dto: KaspiWebhookDTO, signature: String?) async throws -> KaspiWebhookResponseDTO {
        try validateKaspiSignature(dto, signature: signature)

        if let existing = try await PaymentEvent.query(on: req.db)
            .filter(\.$eventID == dto.eventID)
            .first() {
            return KaspiWebhookResponseDTO(
                accepted: true,
                duplicate: true,
                paymentID: existing.paymentID
            )
        }

        let event = PaymentEvent(
            userID: nil,
            eventID: dto.eventID,
            paymentID: dto.paymentID,
            provider: "kaspi",
            purpose: "kaspi_webhook",
            amountTenge: dto.amountTenge,
            status: dto.status,
            metadataJSON: dto.signature.map { "signature=\($0)" }
        )
        try await event.save(on: req.db)

        return KaspiWebhookResponseDTO(
            accepted: true,
            duplicate: false,
            paymentID: dto.paymentID
        )
    }

    private func validateKaspiSignature(_ dto: KaspiWebhookDTO, signature: String?) throws {
        guard let secret = Environment.get("KASPI_WEBHOOK_SECRET"), !secret.isEmpty else {
            return
        }

        guard let signature, !signature.isEmpty else {
            throw Abort(.unauthorized, reason: "Missing Kaspi webhook signature")
        }

        let payload = KaspiWebhookSignature.canonicalPayload(
            eventID: dto.eventID,
            paymentID: dto.paymentID,
            amountTenge: dto.amountTenge,
            status: dto.status
        )

        guard KaspiWebhookSignature.isValid(
            signature: signature,
            payload: payload,
            secret: secret
        ) else {
            throw Abort(.unauthorized, reason: "Invalid Kaspi webhook signature")
        }
    }
}
