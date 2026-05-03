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

    func testRideMatchedBroadcastPayloadUsesFlatKeys() throws {
        let driverID = UUID(uuidString: "00000000-0000-0000-0000-000000000042")!
        let payload = RideMatchedBroadcastDTO(driverId: driverID)
        let data = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(object["event"] as? String, "ride_matched")
        XCTAssertEqual(object["driverId"] as? String, driverID.uuidString)
        XCTAssertEqual(object["driverName"] as? String, "Асан Бекович")
        XCTAssertEqual(object["driverRating"] as? Double, 4.9)
        XCTAssertEqual(object["vehiclePlate"] as? String, "777 ABA 02")
        XCTAssertEqual(object["vehicleModel"] as? String, "Chevrolet Nexia")
        XCTAssertEqual(object["estimatedArrival"] as? Int, 4)
        XCTAssertNil(object["payload"])
    }
}
