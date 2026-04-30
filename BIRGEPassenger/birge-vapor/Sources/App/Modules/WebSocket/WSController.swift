import Vapor

struct WSController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.webSocket("ws") { req, ws in
            self.handle(req: req, ws: ws)
        }
    }

    private func handle(req: Request, ws: WebSocket) {
        let payload: BIRGEJWTPayload
        do {
            payload = try req.jwt.verify(as: BIRGEJWTPayload.self)
            guard payload.type == .access else {
                ws.close(promise: nil)
                return
            }
        } catch {
            req.logger.warning("WebSocket authentication failed: \(error)")
            ws.close(promise: nil)
            return
        }

        let connectionID = UUID()
        Task {
            await req.application.wsHub.connect(id: connectionID, socket: ws)
        }

        ws.send("{\"type\":\"connected\",\"userId\":\"\(payload.userID)\"}")

        ws.onText { _, text in
            if text == "ping" {
                ws.send("pong")
                return
            }

            let message = "{\"type\":\"echo\",\"userId\":\"\(payload.userID)\",\"message\":\"\(text)\"}"
            Task {
                await req.application.wsHub.broadcast(message)
            }
        }

        ws.onClose.whenComplete { _ in
            Task {
                await req.application.wsHub.disconnect(id: connectionID)
            }
        }
    }
}
