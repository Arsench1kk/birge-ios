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
}
