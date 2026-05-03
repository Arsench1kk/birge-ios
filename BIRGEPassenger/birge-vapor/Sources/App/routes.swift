import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("api", "v1")
    try api.register(collection: AuthController())
    try api.register(collection: RidesController())
    try api.register(collection: CorridorsController())
    try api.register(collection: SubscriptionsController())
    try api.register(collection: PaymentsController())
    try api.register(collection: LocationsController())
    try api.register(collection: DriversController())

    // WebSocket
    app.webSocket("ws", "ride", ":rideId") { req, ws in
        let controller = WSController()
        do {
            try await controller.handleConnection(req: req, ws: ws)
        } catch {
            try? await ws.close()
        }
    }

    if app.environment != .production {
        app.post("debug", "match-ride", use: WSController().debugMatchRide)
    }
}
