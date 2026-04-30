import Fluent

struct CreateDriverProfiles: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(DriverProfile.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("vehicle_model", .string)
            .field("license_plate", .string)
            .field("kyc_status", .string, .required)
            .field("subscription_tier", .string)
            .field("created_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(DriverProfile.schema).delete()
    }
}
