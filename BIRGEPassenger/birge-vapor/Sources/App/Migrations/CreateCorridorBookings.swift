import Fluent

struct CreateCorridorBookings: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(CorridorBooking.schema)
            .id()
            .field("corridor_id", .uuid, .required, .references(Corridor.schema, .id, onDelete: .cascade))
            .field("passenger_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("status", .string, .required)
            .field("booked_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "corridor_id", "passenger_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(CorridorBooking.schema).delete()
    }
}
