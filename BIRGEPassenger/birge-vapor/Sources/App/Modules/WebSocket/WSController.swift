import Vapor

struct WSController {
    func handleConnection(req: Request, ws: WebSocket) async throws {
        let payload: BIRGEJWTPayload
        do {
            payload = try req.jwt.verify(as: BIRGEJWTPayload.self)
            guard payload.type == .access else {
                try await ws.close()
                return
            }
        } catch {
            req.logger.warning("WebSocket authentication failed: \(error)")
            try await ws.close()
            return
        }

        let connectionID = UUID()
        Task {
            await req.application.wsHub.connect(id: connectionID, socket: ws)
        }

        try await ws.send("{\"type\":\"connected\",\"userId\":\"\(payload.userID)\"}")

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
