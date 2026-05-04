import XCTest
@testable import App

final class DriverOfferPolicyTests: XCTestCase {
    func testOldRequestedRidesAreHiddenFromDriverOffers() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let oldRequest = now.addingTimeInterval(-16 * 60)

        XCTAssertFalse(DriverOfferPolicy.isVisibleToDriver(
            status: .requested,
            assignedDriverID: nil,
            requestedAt: oldRequest,
            wasDeclined: false,
            now: now
        ))
    }

    func testDeclinedRidesAreHiddenOnlyForThatDriverDecision() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let freshRequest = now.addingTimeInterval(-5 * 60)

        XCTAssertFalse(DriverOfferPolicy.isVisibleToDriver(
            status: .requested,
            assignedDriverID: nil,
            requestedAt: freshRequest,
            wasDeclined: true,
            now: now
        ))

        XCTAssertTrue(DriverOfferPolicy.isVisibleToDriver(
            status: .requested,
            assignedDriverID: nil,
            requestedAt: freshRequest,
            wasDeclined: false,
            now: now
        ))
    }

    func testAssignedOrInactiveRidesAreHiddenFromDriverOffers() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let freshRequest = now.addingTimeInterval(-5 * 60)
        let driverID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        XCTAssertFalse(DriverOfferPolicy.isVisibleToDriver(
            status: .requested,
            assignedDriverID: driverID,
            requestedAt: freshRequest,
            wasDeclined: false,
            now: now
        ))

        XCTAssertFalse(DriverOfferPolicy.isVisibleToDriver(
            status: .cancelled,
            assignedDriverID: nil,
            requestedAt: freshRequest,
            wasDeclined: false,
            now: now
        ))
    }
}
