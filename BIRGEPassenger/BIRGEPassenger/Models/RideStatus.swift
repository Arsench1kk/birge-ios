import Foundation

enum RideStatus: String, Equatable, Sendable {
    case requested
    case matched
    case driverAccepted
    case driverArriving
    case passengerWait
    case inProgress
    case completed
    case cancelled
}
