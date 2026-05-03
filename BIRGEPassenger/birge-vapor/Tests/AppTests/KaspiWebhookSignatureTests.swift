import XCTest
@testable import App

final class KaspiWebhookSignatureTests: XCTestCase {
    func testSignatureValidationAcceptsExpectedDigest() {
        let paymentID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let payload = KaspiWebhookSignature.canonicalPayload(
            eventID: "kaspi-event-1",
            paymentID: paymentID,
            amountTenge: 1200,
            status: "paid"
        )
        let signature = KaspiWebhookSignature.sign(
            payload: payload,
            secret: "test-secret"
        )

        XCTAssertTrue(KaspiWebhookSignature.isValid(
            signature: signature,
            payload: payload,
            secret: "test-secret"
        ))
    }

    func testSignatureValidationRejectsWrongSecret() {
        let paymentID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let payload = KaspiWebhookSignature.canonicalPayload(
            eventID: "kaspi-event-1",
            paymentID: paymentID,
            amountTenge: 1200,
            status: "paid"
        )
        let signature = KaspiWebhookSignature.sign(
            payload: payload,
            secret: "test-secret"
        )

        XCTAssertFalse(KaspiWebhookSignature.isValid(
            signature: signature,
            payload: payload,
            secret: "wrong-secret"
        ))
    }
}
