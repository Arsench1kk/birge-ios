import CryptoKit
import Foundation

enum KaspiWebhookSignature {
    static func canonicalPayload(
        eventID: String,
        paymentID: UUID,
        amountTenge: Int,
        status: String
    ) -> String {
        [
            eventID,
            paymentID.uuidString.lowercased(),
            String(amountTenge),
            status
        ].joined(separator: "|")
    }

    static func sign(payload: String, secret: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(payload.utf8),
            using: key
        )
        return signature.map { String(format: "%02x", $0) }.joined()
    }

    static func isValid(signature: String, payload: String, secret: String) -> Bool {
        let expected = sign(payload: payload, secret: secret)
        return timingSafeEqual(signature.lowercased(), expected)
    }

    private static func timingSafeEqual(_ lhs: String, _ rhs: String) -> Bool {
        let lhsBytes = Array(lhs.utf8)
        let rhsBytes = Array(rhs.utf8)
        guard lhsBytes.count == rhsBytes.count else { return false }

        var difference: UInt8 = 0
        for index in lhsBytes.indices {
            difference |= lhsBytes[index] ^ rhsBytes[index]
        }
        return difference == 0
    }
}
