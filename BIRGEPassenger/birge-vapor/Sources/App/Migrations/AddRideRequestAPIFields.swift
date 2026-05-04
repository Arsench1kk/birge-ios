import Fluent

struct AddRideRequestAPIFields: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Ride.schema)
            .field("tier", .string)
            .field("created_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Ride.schema)
            .deleteField("tier")
            .deleteField("created_at")
            .update()
    }
}
