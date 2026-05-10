import Fluent

/// Additive migration: adds schedule/recurrence fields to corridors for subscription commute.
struct AddCorridorScheduleFields: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Corridor.schema)
            .field("weekdays", .array(of: .string))
            .field("departure_window_start", .string)
            .field("departure_window_end", .string)
            .field("is_recurring", .bool, .sql(.default(false)))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Corridor.schema)
            .deleteField("weekdays")
            .deleteField("departure_window_start")
            .deleteField("departure_window_end")
            .deleteField("is_recurring")
            .update()
    }
}
