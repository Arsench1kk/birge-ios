import XCTest
@testable import App

final class AuthTests: XCTestCase {
    func testAccessPayloadCarriesCoreClaims() throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!.uuidString
        let payload = BIRGEJWTPayload(
            userID: userID,
            role: User.UserRole.driver.rawValue,
            type: .access,
            expiration: Date().addingTimeInterval(3600)
        )

        XCTAssertEqual(payload.userID, userID)
        XCTAssertEqual(payload.role, User.UserRole.driver.rawValue)
        XCTAssertEqual(payload.type, .access)
        XCTAssertFalse(payload.jti.isEmpty)
    }
}
