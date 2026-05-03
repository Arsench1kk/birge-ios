import Fluent

struct CreateDriverLocationRecords: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(DriverLocationRecord.schema)
            .id()
            .field("ride_id", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("user_role", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("timestamp", .double, .required)
            .field("accuracy", .double)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(DriverLocationRecord.schema).delete()
    }
}
