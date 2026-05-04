import Fluent
import Vapor

final class DriverRideDecision: Model, Content, @unchecked Sendable {
    static let schema = "driver_ride_decisions"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "ride_id")
    var ride: Ride

    @Parent(key: "driver_id")
    var driver: User

    @Field(key: "decision")
    var decision: Decision

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    enum Decision: String, Codable, Sendable {
        case accepted
        case declined
    }

    init() { }

    init(
        id: UUID? = nil,
        rideID: UUID,
        driverID: UUID,
        decision: Decision
    ) {
        self.id = id
        self.$ride.id = rideID
        self.$driver.id = driverID
        self.decision = decision
    }
}
