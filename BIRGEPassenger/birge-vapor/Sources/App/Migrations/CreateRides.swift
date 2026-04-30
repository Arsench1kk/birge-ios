import Fluent

struct CreateRides: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Ride.schema)
            .id()
            .field("passenger_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("driver_id", .uuid, .references(User.schema, .id, onDelete: .setNull))
            .field("status", .string, .required)
            .field("origin_lat", .double, .required)
            .field("origin_lng", .double, .required)
            .field("dest_lat", .double, .required)
            .field("dest_lng", .double, .required)
            .field("fare_tenge", .int)
            .field("requested_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Ride.schema).delete()
    }
}
