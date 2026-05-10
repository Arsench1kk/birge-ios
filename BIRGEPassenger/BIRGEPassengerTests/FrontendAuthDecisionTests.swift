import XCTest
@testable import BIRGECore

final class FrontendAuthDecisionTests: XCTestCase {
    func testUnknownPassengerPhoneRoutesToRegistration() async {
        let decision = await MockSessionClient.mockValue.passengerAuthDecision(
            BIRGEProductFixtures.Phones.unknownPassenger
        )

        XCTAssertEqual(decision, .registration)
    }

    func testKnownPassengerIncompleteSetupResumesExactStep() async {
        let decision = await MockSessionClient.mockValue.passengerAuthDecision(
            BIRGEProductFixtures.Phones.incompletePassenger
        )

        XCTAssertEqual(decision, .resumeSetup(.routeDestination))
    }

    func testKnownPassengerCompleteProfileWithoutRouteStartsFirstRouteSetup() async {
        let decision = await MockSessionClient.mockValue.passengerAuthDecision(
            BIRGEProductFixtures.Phones.completePassengerNoRoute
        )

        XCTAssertEqual(decision, .firstRouteSetup)
    }

    func testKnownPassengerWithRouteWithoutPlanRoutesToSubscriptionSelection() async {
        let decision = await MockSessionClient.mockValue.passengerAuthDecision(
            BIRGEProductFixtures.Phones.passengerWithRouteNoPlan
        )

        XCTAssertEqual(decision, .subscriptionSelection)
    }

    func testKnownPassengerWithActiveRouteAndPlanRoutesHome() async {
        let decision = await MockSessionClient.mockValue.passengerAuthDecision(
            BIRGEProductFixtures.Phones.activePassenger
        )

        XCTAssertEqual(decision, .home)
    }

    func testUnknownDriverPhoneStartsOnboarding() async {
        let decision = await MockSessionClient.mockValue.driverAuthDecision(
            BIRGEProductFixtures.Phones.unknownDriver
        )

        XCTAssertEqual(decision, .onboarding(.profile))
    }

    func testPendingDriverRoutesToVerificationPending() async {
        let decision = await MockSessionClient.mockValue.driverAuthDecision(
            BIRGEProductFixtures.Phones.pendingDriver
        )

        XCTAssertEqual(decision, .verificationPending)
    }

    func testFailedDriverRoutesToVerificationFailed() async {
        let decision = await MockSessionClient.mockValue.driverAuthDecision(
            BIRGEProductFixtures.Phones.failedDriver
        )

        XCTAssertEqual(decision, .verificationFailed)
    }

    func testApprovedDriverWithoutActiveCorridorWaitsForFirstCorridor() async {
        let decision = await MockSessionClient.mockValue.driverAuthDecision(
            BIRGEProductFixtures.Phones.approvedDriverNoCorridor
        )

        XCTAssertEqual(decision, .waitingForFirstCorridor)
    }

    func testActiveDriverRoutesHome() async {
        let decision = await MockSessionClient.mockValue.driverAuthDecision(
            BIRGEProductFixtures.Phones.activeDriver
        )

        XCTAssertEqual(decision, .home)
    }

    func testPassengerPlanFixturesUseCurrentProductIDs() async {
        let plans = await PassengerSubscriptionClient.mockValue.plans()

        XCTAssertEqual(plans.map(\.type), [.soloCorridor, .multiCorridor, .flexPack])
        XCTAssertTrue(plans.first { $0.type == .multiCorridor }?.isRecommended == true)
        XCTAssertFalse(plans.first { $0.type == .soloCorridor }?.includesPerRidePricing ?? true)
        XCTAssertFalse(plans.first { $0.type == .multiCorridor }?.includesPerRidePricing ?? true)
    }

    func testDriverPlanFixturesUseCurrentPricesAndZeroCommission() async {
        let plans = await DriverPlanClient.mockValue.plans()

        XCTAssertEqual(plans.map(\.type), [.peakStarter, .starter, .professional, .premium])
        XCTAssertEqual(plans.first { $0.type == .peakStarter }?.monthlyPriceTenge, 9_900)
        XCTAssertEqual(plans.first { $0.type == .starter }?.monthlyPriceTenge, 19_000)
        XCTAssertEqual(plans.first { $0.type == .professional }?.monthlyPriceTenge, 28_000)
        XCTAssertEqual(plans.first { $0.type == .premium }?.monthlyPriceTenge, 38_000)
        XCTAssertTrue(plans.allSatisfy(\.includesZeroCommission))
        XCTAssertTrue(plans.allSatisfy(\.paymentStartsAfterFirstCorridor))
    }
}
