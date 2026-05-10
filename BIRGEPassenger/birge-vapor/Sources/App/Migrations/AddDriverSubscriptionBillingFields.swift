import Fluent

/// Additive migration: adds subscription billing fields to driver profiles.
struct AddDriverSubscriptionBillingFields: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(DriverProfile.schema)
            .field("subscription_price_tenge", .int)
            .field("subscription_status", .string)
            .field("trial_end_date", .date)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(DriverProfile.schema)
            .deleteField("subscription_price_tenge")
            .deleteField("subscription_status")
            .deleteField("trial_end_date")
            .update()
    }
}
