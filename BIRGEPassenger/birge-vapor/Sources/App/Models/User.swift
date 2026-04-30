import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "phone")
    var phone: String

    @OptionalField(key: "email")
    var email: String?

    @OptionalField(key: "password_hash")
    var passwordHash: String?

    @Field(key: "role")
    var role: UserRole

    @OptionalField(key: "name")
    var name: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    enum UserRole: String, Codable, Sendable {
        case passenger
        case driver
    }

    init() { }

    init(
        id: UUID? = nil,
        phone: String,
        email: String? = nil,
        passwordHash: String? = nil,
        role: UserRole,
        name: String? = nil
    ) {
        self.id = id
        self.phone = phone
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
        self.name = name
    }
}
