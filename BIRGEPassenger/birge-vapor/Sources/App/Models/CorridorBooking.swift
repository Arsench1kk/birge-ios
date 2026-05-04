import Fluent
import Vapor

final class CorridorBooking: Model, Content, @unchecked Sendable {
    static let schema = "corridor_bookings"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "corridor_id")
    var corridor: Corridor

    @Parent(key: "passenger_id")
    var passenger: User

    @Field(key: "status")
    var status: String

    @Timestamp(key: "booked_at", on: .create)
    var bookedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(
        id: UUID? = nil,
        corridorID: UUID,
        passengerID: UUID,
        status: String = "confirmed"
    ) {
        self.id = id
        self.$corridor.id = corridorID
        self.$passenger.id = passengerID
        self.status = status
    }
}
