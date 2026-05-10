import Fluent

struct CreateRecurringRoutes: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(RecurringRoute.schema)
            .id()
            .field("passenger_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("origin_name", .string, .required)
            .field("origin_lat", .double, .required)
            .field("origin_lng", .double, .required)
            .field("destination_name", .string, .required)
            .field("destination_lat", .double, .required)
            .field("destination_lng", .double, .required)
            .field("weekdays", .array(of: .string), .required)
            .field("departure_window", .string, .required)
            .field("corridor_id", .uuid, .references(Corridor.schema, .id, onDelete: .setNull))
            .field("is_active", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(RecurringRoute.schema).delete()
    }
}
