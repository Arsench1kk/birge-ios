import Fluent

struct CreatePaymentEvents: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(PaymentEvent.schema)
            .id()
            .field("user_id", .uuid, .references(User.schema, .id, onDelete: .setNull))
            .field("event_id", .string, .required)
            .field("payment_id", .uuid, .required)
            .field("provider", .string, .required)
            .field("purpose", .string, .required)
            .field("amount_tenge", .int, .required)
            .field("status", .string, .required)
            .field("checkout_url", .string)
            .field("metadata_json", .string)
            .field("created_at", .datetime)
            .unique(on: "event_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(PaymentEvent.schema).delete()
    }
}
