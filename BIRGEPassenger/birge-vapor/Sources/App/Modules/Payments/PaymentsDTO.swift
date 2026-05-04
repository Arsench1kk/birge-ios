import Vapor

struct KaspiCheckoutRequestDTO: Content {
    let purpose: String
    let amountTenge: Int
    let planID: String?
}

struct KaspiCheckoutResponseDTO: Content {
    let paymentID: UUID
    let provider: String
    let status: String
    let amountTenge: Int
    let kaspiDeepLink: String
    let message: String
}

struct KaspiWebhookDTO: Content {
    let eventID: String
    let paymentID: UUID
    let amountTenge: Int
    let status: String
    let signature: String?
}

struct KaspiWebhookResponseDTO: Content {
    let accepted: Bool
    let duplicate: Bool
    let paymentID: UUID
}
