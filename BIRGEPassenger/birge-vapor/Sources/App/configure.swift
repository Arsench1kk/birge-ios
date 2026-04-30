import Fluent
import FluentPostgresDriver
import JWT
import Leaf
import Redis
import Vapor

public func configure(_ app: Application) async throws {
    app.logger.logLevel = .info

    app.databases.use(
        .postgres(
            configuration: .init(
                hostname: Environment.get("DB_HOST") ?? "localhost",
                port: Environment.get("DB_PORT").flatMap(Int.init) ?? 5432,
                username: Environment.get("DB_USER") ?? "birge",
                password: Environment.get("DB_PASS") ?? "birge",
                database: Environment.get("DB_NAME") ?? "birge_dev",
                tls: .disable
            )
        ),
        as: .psql
    )

    app.redis.configuration = try .init(
        hostname: Environment.get("REDIS_HOST") ?? "localhost",
        port: Environment.get("REDIS_PORT").flatMap(Int.init) ?? 6379
    )

    app.views.use(.leaf)

    let jwtSecret = Environment.get("JWT_SECRET") ?? "dev_secret_change_in_prod"
    await app.jwt.keys.add(hmac: jwtSecret, digestAlgorithm: .sha256)

    app.migrations.add(CreateUsers())
    app.migrations.add(CreateDriverProfiles())
    app.migrations.add(CreateRides())

    try await app.autoMigrate()
    try routes(app)
}
