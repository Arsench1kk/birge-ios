import Fluent
import Vapor

// TODO(subscription-pivot): Extend with plan_type (solo_corridor/multi_corridor/flex_pack),
// billing_period_start/end, status, price_tenge, flex_rides_total/used, kaspi_payment_id.
// Current model only stores a plan_id string — insufficient for subscription commute.
final class PassengerSubscription: Model, Content, @unchecked Sendable {
    static let schema = "passenger_subscriptions"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "plan_id")
    var planID: String

    @Timestamp(key: "activated_at", on: .create)
    var activatedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, userID: UUID, planID: String) {
        self.id = id
        self.$user.id = userID
        self.planID = planID
    }
}
