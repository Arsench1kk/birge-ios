import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("phone", .string, .required)
            .field("email", .string)
            .field("password_hash", .string)
            .field("role", .string, .required)
            .field("name", .string)
            .field("created_at", .datetime)
            .unique(on: "phone")
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
