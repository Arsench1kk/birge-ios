import Dependencies
import Foundation

public enum FrontendEnvironment: Equatable, Sendable {
    case mock

    public static func applyMock(to values: inout DependencyValues) {
        values.mockSessionClient = .mockValue
        values.passengerProfileClient = .mockValue
        values.passengerRouteClient = .mockValue
        values.passengerSubscriptionClient = .mockValue
        values.driverOnboardingClient = .mockValue
        values.driverPlanClient = .mockValue
        values.driverCorridorClient = .mockValue
    }
}
