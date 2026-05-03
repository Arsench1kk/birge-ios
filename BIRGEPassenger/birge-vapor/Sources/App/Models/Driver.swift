import Fluent
import Vapor

final class DriverProfile: Model, Content, @unchecked Sendable {
    static let schema = "driver_profiles"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @OptionalField(key: "vehicle_model")
    var vehicleModel: String?

    @OptionalField(key: "license_plate")
    var licensePlate: String?

    @OptionalField(key: "first_name")
    var firstName: String?

    @OptionalField(key: "last_name")
    var lastName: String?

    @OptionalField(key: "birth_date")
    var birthDate: String?

    @OptionalField(key: "iin")
    var iin: String?

    @OptionalField(key: "vehicle_make")
    var vehicleMake: String?

    @OptionalField(key: "vehicle_year")
    var vehicleYear: String?

    @OptionalField(key: "vehicle_color")
    var vehicleColor: String?

    @OptionalField(key: "seats")
    var seats: Int?

    @OptionalField(key: "uploaded_documents")
    var uploadedDocuments: [String]?

    @Field(key: "kyc_status")
    var kycStatus: String

    @OptionalField(key: "subscription_tier")
    var subscriptionTier: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(
        id: UUID? = nil,
        userID: UUID,
        vehicleModel: String? = nil,
        licensePlate: String? = nil,
        kycStatus: String,
        subscriptionTier: String? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.vehicleModel = vehicleModel
        self.licensePlate = licensePlate
        self.kycStatus = kycStatus
        self.subscriptionTier = subscriptionTier
    }
}
