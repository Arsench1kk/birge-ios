import Fluent

struct CreatePassengerSubscriptions: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(PassengerSubscription.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("plan_id", .string, .required)
            .field("activated_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(PassengerSubscription.schema).delete()
    }
}
