import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        ["status": "ok"]
    }

    let api = app.grouped("api", "v1")
    api.get("health") { _ in
        ["status": "ok"]
    }

    let authController = AuthController()
    let ridesController = RidesController()
    let wsController = WSController()

    try authController.boot(routes: app)
    try ridesController.boot(routes: app)
    try wsController.boot(routes: app)

    try authController.boot(routes: api)
    try ridesController.boot(routes: api)
    try wsController.boot(routes: api)
}
