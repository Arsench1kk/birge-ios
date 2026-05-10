import Fluent
import Vapor

/// A passenger's declared recurring commute route.
/// Passengers set these during onboarding; BIRGE matches them to corridors.
final class RecurringRoute: Model, Content, @unchecked Sendable {
    static let schema = "recurring_routes"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "passenger_id")
    var passenger: User

    @Field(key: "origin_name")
    var originName: String

    @Field(key: "origin_lat")
    var originLat: Double

    @Field(key: "origin_lng")
    var originLng: Double

    @Field(key: "destination_name")
    var destinationName: String

    @Field(key: "destination_lat")
    var destinationLat: Double

    @Field(key: "destination_lng")
    var destinationLng: Double

    @Field(key: "weekdays")
    var weekdays: [String]

    @Field(key: "departure_window")
    var departureWindow: String

    @OptionalParent(key: "corridor_id")
    var corridor: Corridor?

    @Field(key: "is_active")
    var isActive: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        passengerID: UUID,
        originName: String,
        originLat: Double,
        originLng: Double,
        destinationName: String,
        destinationLat: Double,
        destinationLng: Double,
        weekdays: [String],
        departureWindow: String,
        corridorID: UUID? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.$passenger.id = passengerID
        self.originName = originName
        self.originLat = originLat
        self.originLng = originLng
        self.destinationName = destinationName
        self.destinationLat = destinationLat
        self.destinationLng = destinationLng
        self.weekdays = weekdays
        self.departureWindow = departureWindow
        self.$corridor.id = corridorID
        self.isActive = isActive
    }
}
