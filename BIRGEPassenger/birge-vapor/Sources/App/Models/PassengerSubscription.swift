import Fluent
import Vapor

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
