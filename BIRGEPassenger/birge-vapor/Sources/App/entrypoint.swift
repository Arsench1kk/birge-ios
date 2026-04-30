import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var environment = try Environment.detect()
        try LoggingSystem.bootstrap(from: &environment)

        let app = Application(environment)
        defer { app.shutdown() }

        try await configure(app)
        try app.run()
    }
}
