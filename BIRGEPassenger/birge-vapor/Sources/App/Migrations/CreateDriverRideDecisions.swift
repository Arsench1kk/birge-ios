import Fluent

struct CreateDriverRideDecisions: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(DriverRideDecision.schema)
            .id()
            .field("ride_id", .uuid, .required, .references(Ride.schema, .id, onDelete: .cascade))
            .field("driver_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("decision", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "ride_id", "driver_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(DriverRideDecision.schema).delete()
    }
}
