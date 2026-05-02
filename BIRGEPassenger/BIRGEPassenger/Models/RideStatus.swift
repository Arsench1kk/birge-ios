import Foundation

enum RideStatus: String, Equatable, Sendable, Codable {
    case requested
    case matched
    case driverAccepted  = "driver_accepted"
    case driverArriving  = "driver_arriving"
    case passengerWait   = "passenger_wait"
    case inProgress      = "in_progress"
    case completed
    case cancelled
}
