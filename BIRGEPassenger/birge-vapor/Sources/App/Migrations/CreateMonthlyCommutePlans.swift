import Fluent

struct CreateMonthlyCommutePlans: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(MonthlyCommutePlan.schema)
            .id()
            .field("passenger_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("plan_type", .string, .required)
            .field("billing_period_start", .date, .required)
            .field("billing_period_end", .date, .required)
            .field("status", .string, .required)
            .field("price_tenge", .int, .required)
            .field("flex_rides_total", .int)
            .field("flex_rides_used", .int)
            .field("kaspi_payment_id", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(MonthlyCommutePlan.schema).delete()
    }
}
