import Fluent

struct CreateCorridors: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Corridor.schema)
            .id()
            .field("name", .string, .required)
            .field("origin_name", .string, .required)
            .field("destination_name", .string, .required)
            .field("origin_lat", .double, .required)
            .field("origin_lng", .double, .required)
            .field("destination_lat", .double, .required)
            .field("destination_lng", .double, .required)
            .field("departure", .string, .required)
            .field("time_of_day", .string, .required)
            .field("seats_left", .int, .required)
            .field("seats_total", .int, .required)
            .field("price_tenge", .int, .required)
            .field("match_percent", .int, .required)
            .field("passenger_initials", .array(of: .string), .required)
            .field("is_active", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Corridor.schema).delete()
    }
}
