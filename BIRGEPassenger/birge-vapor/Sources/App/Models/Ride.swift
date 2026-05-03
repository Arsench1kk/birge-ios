import Fluent
import Vapor

final class Ride: Model, Content, @unchecked Sendable {
    static let schema = "rides"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "passenger_id")
    var passenger: User

    @OptionalParent(key: "driver_id")
    var driver: User?

    @Field(key: "status")
    var status: RideStatus

    @Field(key: "origin_lat")
    var originLat: Double

    @Field(key: "origin_lng")
    var originLng: Double

    @Field(key: "dest_lat")
    var destLat: Double

    @Field(key: "dest_lng")
    var destLng: Double

    @OptionalField(key: "origin_name")
    var originName: String?

    @OptionalField(key: "destination_name")
    var destinationName: String?

    @OptionalField(key: "tier")
    var tier: String?

    @OptionalField(key: "fare_tenge")
    var fareTenge: Int?

    @Timestamp(key: "requested_at", on: .create)
    var requestedAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    enum RideStatus: String, Codable, Sendable {
        case requested
        case matched
        case driverAccepted = "driver_accepted"
        case driverArriving = "driver_arriving"
        case passengerWait = "passenger_wait"
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    init() { }

    init(
        id: UUID? = nil,
        passengerID: UUID,
        driverID: UUID? = nil,
        status: RideStatus,
        originLat: Double,
        originLng: Double,
        destLat: Double,
        destLng: Double,
        originName: String? = nil,
        destinationName: String? = nil,
        tier: String? = nil,
        fareTenge: Int? = nil
    ) {
        self.id = id
        self.$passenger.id = passengerID
        self.$driver.id = driverID
        self.status = status
        self.originLat = originLat
        self.originLng = originLng
        self.destLat = destLat
        self.destLng = destLng
        self.originName = originName
        self.destinationName = destinationName
        self.tier = tier
        self.fareTenge = fareTenge
    }
}
