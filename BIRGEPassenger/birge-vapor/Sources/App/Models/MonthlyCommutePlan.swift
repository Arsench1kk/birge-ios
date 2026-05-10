import Fluent
import Vapor

/// A passenger's monthly subscription commute plan.
/// plan_type: "solo_corridor" | "multi_corridor" | "flex_pack"
final class MonthlyCommutePlan: Model, Content, @unchecked Sendable {
    static let schema = "monthly_commute_plans"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "passenger_id")
    var passenger: User

    @Field(key: "plan_type")
    var planType: String

    @Field(key: "billing_period_start")
    var billingPeriodStart: Date

    @Field(key: "billing_period_end")
    var billingPeriodEnd: Date

    @Field(key: "status")
    var status: String

    @Field(key: "price_tenge")
    var priceTenge: Int

    @OptionalField(key: "flex_rides_total")
    var flexRidesTotal: Int?

    @OptionalField(key: "flex_rides_used")
    var flexRidesUsed: Int?

    @OptionalField(key: "kaspi_payment_id")
    var kaspiPaymentID: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    enum PlanType: String, Codable, Sendable {
        case soloCorridor = "solo_corridor"
        case multiCorridor = "multi_corridor"
        case flexPack = "flex_pack"
    }

    enum PlanStatus: String, Codable, Sendable {
        case pendingPayment = "pending_payment"
        case active
        case cancelled
        case expired
    }

    init() {}

    init(
        id: UUID? = nil,
        passengerID: UUID,
        planType: String,
        billingPeriodStart: Date,
        billingPeriodEnd: Date,
        status: String = PlanStatus.pendingPayment.rawValue,
        priceTenge: Int,
        flexRidesTotal: Int? = nil,
        flexRidesUsed: Int? = nil,
        kaspiPaymentID: String? = nil
    ) {
        self.id = id
        self.$passenger.id = passengerID
        self.planType = planType
        self.billingPeriodStart = billingPeriodStart
        self.billingPeriodEnd = billingPeriodEnd
        self.status = status
        self.priceTenge = priceTenge
        self.flexRidesTotal = flexRidesTotal
        self.flexRidesUsed = flexRidesUsed
        self.kaspiPaymentID = kaspiPaymentID
    }
}
