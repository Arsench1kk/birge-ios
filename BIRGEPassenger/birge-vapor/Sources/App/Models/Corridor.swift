import Fluent
import Vapor

// TODO(subscription-pivot): Add weekdays, departure_window_start/end, is_recurring fields.
// Current model treats corridors as static listings without schedule recurrence.
final class Corridor: Model, Content, @unchecked Sendable {
    static let schema = "corridors"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "origin_name")
    var originName: String

    @Field(key: "destination_name")
    var destinationName: String

    @Field(key: "origin_lat")
    var originLat: Double

    @Field(key: "origin_lng")
    var originLng: Double

    @Field(key: "destination_lat")
    var destinationLat: Double

    @Field(key: "destination_lng")
    var destinationLng: Double

    @Field(key: "departure")
    var departure: String

    @Field(key: "time_of_day")
    var timeOfDay: String

    @Field(key: "seats_left")
    var seatsLeft: Int

    @Field(key: "seats_total")
    var seatsTotal: Int

    @Field(key: "price_tenge")
    var priceTenge: Int

    @Field(key: "match_percent")
    var matchPercent: Int

    @Field(key: "passenger_initials")
    var passengerInitials: [String]

    @Field(key: "is_active")
    var isActive: Bool

    // Subscription-pivot: schedule fields for recurring corridors
    @OptionalField(key: "weekdays")
    var weekdays: [String]?

    @OptionalField(key: "departure_window_start")
    var departureWindowStart: String?

    @OptionalField(key: "departure_window_end")
    var departureWindowEnd: String?

    @OptionalField(key: "is_recurring")
    var isRecurring: Bool?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        originName: String,
        destinationName: String,
        originLat: Double,
        originLng: Double,
        destinationLat: Double,
        destinationLng: Double,
        departure: String,
        timeOfDay: String,
        seatsLeft: Int,
        seatsTotal: Int,
        priceTenge: Int,
        matchPercent: Int,
        passengerInitials: [String],
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.originName = originName
        self.destinationName = destinationName
        self.originLat = originLat
        self.originLng = originLng
        self.destinationLat = destinationLat
        self.destinationLng = destinationLng
        self.departure = departure
        self.timeOfDay = timeOfDay
        self.seatsLeft = seatsLeft
        self.seatsTotal = seatsTotal
        self.priceTenge = priceTenge
        self.matchPercent = matchPercent
        self.passengerInitials = passengerInitials
        self.isActive = isActive
    }
}
