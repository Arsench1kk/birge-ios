import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("api", "v1")
    try api.register(collection: AuthController())
    try api.register(collection: RidesController())

    // WebSocket
    app.webSocket("ws", "ride", ":rideId") { req, ws in
        let controller = WSController()
        do {
            try await controller.handleConnection(req: req, ws: ws)
        } catch {
            try? await ws.close()
        }
    }
}
