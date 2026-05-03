import Fluent

struct AddRideAddressLabels: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Ride.schema)
            .field("origin_name", .string)
            .field("destination_name", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Ride.schema)
            .deleteField("destination_name")
            .deleteField("origin_name")
            .update()
    }
}
