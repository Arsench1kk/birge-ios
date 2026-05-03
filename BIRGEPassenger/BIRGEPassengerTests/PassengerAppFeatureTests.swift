import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class PassengerAppFeatureTests: XCTestCase {
    func testRideMatchedNavigatesToRideFeatureWithDriverInfo() async {
        var initialState = PassengerAppFeature.State()
        initialState.path.append(.searching(SearchingFeature.State(rideId: "ride-123")))

        let driverInfo = SearchingFeature.DriverInfo(
            driverId: "driver-123",
            driverName: "Асан Бекович",
            driverRating: 4.9,
            driverVehicle: "Chevrolet Nexia",
            driverPlate: "777 ABA 02",
            etaSeconds: 240
        )

        let store = TestStore(initialState: initialState) {
            PassengerAppFeature()
        }

        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .searching(
                        .delegate(
                            .rideMatched(rideID: "ride-123", driverInfo)
                        )
                    )
                )
            )
        )

        let path = Array(store.state.path)
        XCTAssertEqual(path.count, 2)
        guard case let .ride(rideState) = path.last else {
            XCTFail("Expected RideFeature at the top of the stack")
            return
        }
        XCTAssertEqual(rideState.rideId, "ride-123")
        XCTAssertEqual(rideState.status, .matched)
        XCTAssertEqual(rideState.etaSeconds, 240)
        XCTAssertEqual(rideState.driverName, "Асан Бекович")
        XCTAssertEqual(rideState.driverRating, 4.9)
        XCTAssertEqual(rideState.driverVehicle, "Chevrolet Nexia")
        XCTAssertEqual(rideState.driverPlate, "777 ABA 02")
    }
}
