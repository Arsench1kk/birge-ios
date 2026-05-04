import XCTest
@testable import App

final class AuthTests: XCTestCase {
    func testUserResponseDTOEncodesProfileFields() throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        let createdAt = Date(timeIntervalSince1970: 1_735_689_600)
        let user = User(
            id: userID,
            phone: "+77771234567",
            email: "passenger@example.com",
            role: .passenger,
            name: "Арсен"
        )
        user.createdAt = createdAt

        let dto = try UserResponseDTO(
            user: user,
            rating: 0.0,
            totalRides: 3
        )
        let data = try JSONEncoder().encode(dto)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(object["id"] as? String, userID.uuidString)
        XCTAssertEqual(object["phone"] as? String, "+77771234567")
        XCTAssertEqual(object["email"] as? String, "passenger@example.com")
        XCTAssertEqual(object["role"] as? String, "passenger")
        XCTAssertEqual(object["name"] as? String, "Арсен")
        XCTAssertEqual(object["rating"] as? Double, 0.0)
        XCTAssertEqual(object["totalRides"] as? Int, 3)
        XCTAssertNotNil(object["createdAt"])
    }

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
