import Fluent

struct AddDriverProfileRegistrationFields: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(DriverProfile.schema)
            .field("first_name", .string)
            .field("last_name", .string)
            .field("birth_date", .string)
            .field("iin", .string)
            .field("vehicle_make", .string)
            .field("vehicle_year", .string)
            .field("vehicle_color", .string)
            .field("seats", .int)
            .field("uploaded_documents", .array(of: .string))
            .field("updated_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(DriverProfile.schema)
            .deleteField("updated_at")
            .deleteField("uploaded_documents")
            .deleteField("seats")
            .deleteField("vehicle_color")
            .deleteField("vehicle_year")
            .deleteField("vehicle_make")
            .deleteField("iin")
            .deleteField("birth_date")
            .deleteField("last_name")
            .deleteField("first_name")
            .update()
    }
}
