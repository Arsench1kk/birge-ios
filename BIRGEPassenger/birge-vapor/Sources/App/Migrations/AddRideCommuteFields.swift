import Fluent

/// Additive migration: links rides to corridors and commute plans for tracking.
struct AddRideCommuteFields: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Ride.schema)
            .field("corridor_id", .uuid, .references(Corridor.schema, .id, onDelete: .setNull))
            .field("recurring_route_id", .uuid, .references(RecurringRoute.schema, .id, onDelete: .setNull))
            .field("commute_plan_id", .uuid, .references(MonthlyCommutePlan.schema, .id, onDelete: .setNull))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Ride.schema)
            .deleteField("corridor_id")
            .deleteField("recurring_route_id")
            .deleteField("commute_plan_id")
            .update()
    }
}
