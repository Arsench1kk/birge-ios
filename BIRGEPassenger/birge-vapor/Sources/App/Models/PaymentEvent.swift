import Fluent
import Vapor

final class PaymentEvent: Model, Content, @unchecked Sendable {
    static let schema = "payment_events"

    @ID(key: .id)
    var id: UUID?

    @OptionalParent(key: "user_id")
    var user: User?

    @Field(key: "event_id")
    var eventID: String

    @Field(key: "payment_id")
    var paymentID: UUID

    @Field(key: "provider")
    var provider: String

    @Field(key: "purpose")
    var purpose: String

    @Field(key: "amount_tenge")
    var amountTenge: Int

    @Field(key: "status")
    var status: String

    @OptionalField(key: "checkout_url")
    var checkoutURL: String?

    @OptionalField(key: "metadata_json")
    var metadataJSON: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(
        id: UUID? = nil,
        userID: UUID?,
        eventID: String,
        paymentID: UUID,
        provider: String,
        purpose: String,
        amountTenge: Int,
        status: String,
        checkoutURL: String? = nil,
        metadataJSON: String? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.eventID = eventID
        self.paymentID = paymentID
        self.provider = provider
        self.purpose = purpose
        self.amountTenge = amountTenge
        self.status = status
        self.checkoutURL = checkoutURL
        self.metadataJSON = metadataJSON
    }
}
