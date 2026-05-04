import Fluent
import Vapor

final class DriverLocationRecord: Model, Content, @unchecked Sendable {
    static let schema = "driver_location_records"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "ride_id")
    var rideID: String

    @Parent(key: "user_id")
    var user: User

    @Field(key: "user_role")
    var userRole: String

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Field(key: "timestamp")
    var timestamp: Double

    @OptionalField(key: "accuracy")
    var accuracy: Double?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(
        rideID: String,
        userID: UUID,
        userRole: String,
        latitude: Double,
        longitude: Double,
        timestamp: Double,
        accuracy: Double?
    ) {
        self.rideID = rideID
        self.$user.id = userID
        self.userRole = userRole
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.accuracy = accuracy
    }
}
