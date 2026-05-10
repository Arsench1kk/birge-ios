import Fluent

struct CreateCommutePlanRoutes: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(CommutePlanRoute.schema)
            .id()
            .field("plan_id", .uuid, .required, .references(MonthlyCommutePlan.schema, .id, onDelete: .cascade))
            .field("recurring_route_id", .uuid, .required, .references(RecurringRoute.schema, .id, onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "plan_id", "recurring_route_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(CommutePlanRoute.schema).delete()
    }
}
