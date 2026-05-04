import XCTest
@testable import App

final class LocationBroadcastTests: XCTestCase {
    func testLocationBroadcastEncodesCanonicalRideEvent() throws {
        let dto = RideLocationBroadcastDTO(
            rideID: "11111111-1111-1111-1111-111111111111",
            record: LocationRecordDTO(
                latitude: 43.238,
                longitude: 76.945,
                timestamp: 1_714_000_000.123,
                accuracy: 8
            ),
            etaSeconds: 240
        )

        let data = try JSONEncoder().encode(dto)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let payload = try XCTUnwrap(object["payload"] as? [String: Any])

        XCTAssertEqual(object["event"] as? String, "ride.location_update")
        XCTAssertEqual(object["ride_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(object["timestamp_ms"] as? Int64, 1_714_000_000_123)
        XCTAssertEqual(payload["lat"] as? Double, 43.238)
        XCTAssertEqual(payload["lng"] as? Double, 76.945)
        XCTAssertEqual(payload["eta_seconds"] as? Int, 240)
    }

    func testRideStatusBroadcastEncodesCanonicalRideEvent() throws {
        let rideID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let passengerID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let driverID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let ride = Ride(
            id: rideID,
            passengerID: passengerID,
            driverID: driverID,
            status: .passengerWait,
            originLat: 43.238,
            originLng: 76.945,
            destLat: 43.221,
            destLng: 76.851,
            tier: "shared",
            fareTenge: 1850
        )
        let profile = DriverProfile(
            userID: driverID,
            vehicleModel: "Camry",
            licensePlate: "123 ABC 02",
            kycStatus: "review"
        )
        profile.vehicleMake = "Toyota"
        profile.vehicleYear = "2018"
        let driver = User(
            id: driverID,
            phone: "+77770000001",
            role: .driver,
            name: "Асан Б."
        )

        let dto = try RideStatusBroadcastDTO(
            ride: ride,
            driverProfile: profile,
            driver: driver
        )
        let data = try JSONEncoder().encode(dto)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let payload = try XCTUnwrap(object["payload"] as? [String: Any])

        XCTAssertEqual(object["event"] as? String, "ride.status_changed")
        XCTAssertEqual(object["ride_id"] as? String, rideID.uuidString)
        XCTAssertEqual(payload["status"] as? String, "passenger_wait")
        XCTAssertEqual(payload["eta_seconds"] as? Int, 2_100)
        XCTAssertEqual(payload["verification_code"] as? String, "0426")
        XCTAssertEqual(payload["driver_name"] as? String, "Асан Б.")
        XCTAssertEqual(payload["driver_vehicle"] as? String, "Toyota Camry 2018")
        XCTAssertEqual(payload["driver_plate"] as? String, "123 ABC 02")
    }

    func testDriverRideOfferUsesStoredAddressLabels() throws {
        let ride = Ride(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            passengerID: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            status: .requested,
            originLat: 43.238,
            originLng: 76.945,
            destLat: 43.262,
            destLng: 76.912,
            originName: "ЖК Алатау, пр. Аль-Фараби",
            destinationName: "Есентай Молл",
            tier: "shared"
        )

        let dto = try DriverRideOfferDTO(ride: ride)

        XCTAssertEqual(dto.pickup, "ЖК Алатау, пр. Аль-Фараби")
        XCTAssertEqual(dto.destination, "Есентай Молл")
        XCTAssertEqual(dto.status, "requested")
    }
}
