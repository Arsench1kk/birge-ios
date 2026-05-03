import Fluent
import Vapor

struct MatchRideDebugRequest: Content {
    let rideId: UUID
    let driverId: UUID
}

struct RideMatchedBroadcastDTO: Content, Equatable {
    let event: String
    let driverId: UUID
    let driverName: String
    let driverRating: Double
    let vehiclePlate: String
    let vehicleModel: String
    let estimatedArrival: Int

    init(
        driverId: UUID,
        driverName: String = "Асан Бекович",
        driverRating: Double = 4.9,
        vehiclePlate: String = "777 ABA 02",
        vehicleModel: String = "Chevrolet Nexia",
        estimatedArrival: Int = 4
    ) {
        self.event = "ride_matched"
        self.driverId = driverId
        self.driverName = driverName
        self.driverRating = driverRating
        self.vehiclePlate = vehiclePlate
        self.vehicleModel = vehicleModel
        self.estimatedArrival = estimatedArrival
    }
}

private struct WebSocketSubscribeMessage: Decodable {
    let type: String
    let channel: String?
}

struct WSController {
    func handleConnection(req: Request, ws: WebSocket) async throws {
        do {
            let payload = try verifyAccessPayload(req: req)
            guard let userID = UUID(uuidString: payload.userID) else {
                throw Abort(.unauthorized, reason: "Invalid token subject")
            }
            guard let rideID = req.parameters.get("rideId", as: UUID.self) else {
                throw Abort(.badRequest, reason: "Invalid ride id")
            }

            _ = try await authorizeAccess(req: req, rideID: rideID, userID: userID)

            let channel = "ride/\(rideID.uuidString)"
            let connectionID = UUID()
            await req.application.wsHub.connect(
                id: connectionID,
                channel: channel,
                socket: ws
            )

            req.logger.info("WebSocket connected: \(channel)")
            try await ws.send("{\"type\":\"connected\",\"channel\":\"\(channel)\",\"userId\":\"\(payload.userID)\"}")

            ws.onText { _, text in
                if text == "ping" {
                    ws.send("pong")
                    return
                }

                guard let data = text.data(using: .utf8),
                      let message = try? JSONDecoder().decode(WebSocketSubscribeMessage.self, from: data),
                      message.type == "subscribe"
                else {
                    return
                }

                let subscribedChannel = message.channel ?? channel
                ws.send("{\"type\":\"subscribed\",\"channel\":\"\(subscribedChannel)\"}")
            }

            ws.onClose.whenComplete { _ in
                Task {
                    await req.application.wsHub.disconnect(id: connectionID)
                }
            }
        } catch {
            req.logger.warning("WebSocket authentication failed: \(error)")
            try await ws.close()
        }
    }

    func debugMatchRide(req: Request) async throws -> RideMatchedBroadcastDTO {
        let dto = try req.content.decode(MatchRideDebugRequest.self)
        guard let ride = try await Ride.find(dto.rideId, on: req.db) else {
            throw Abort(.notFound, reason: "Ride not found")
        }

        if let driver = try await User.find(dto.driverId, on: req.db),
           driver.role == .driver {
            ride.$driver.id = dto.driverId
        }

        ride.status = .matched
        try await ride.save(on: req.db)

        let payload = RideMatchedBroadcastDTO(driverId: dto.driverId)
        let data = try JSONEncoder().encode(payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Could not encode ride_matched event")
        }

        let channel = "ride/\(dto.rideId.uuidString)"
        await req.application.wsHub.broadcast(to: channel, text: text)
        req.logger.info("ride_matched broadcast to \(channel)")
        return payload
    }

    func verifyAccessPayload(req: Request) throws -> BIRGEJWTPayload {
        let token = try req.query.get(String.self, at: "token")
        let payload = try req.jwt.verify(token, as: BIRGEJWTPayload.self)
        guard payload.type == .access else {
            throw Abort(.unauthorized, reason: "Access token is required")
        }
        return payload
    }

    private func authorizeAccess(req: Request, rideID: UUID, userID: UUID) async throws -> Ride {
        guard let ride = try await Ride.find(rideID, on: req.db) else {
            throw Abort(.notFound, reason: "Ride not found")
        }

        if ride.$passenger.id == userID || ride.$driver.id == userID {
            return ride
        }

        throw Abort(.forbidden, reason: "Ride does not belong to authenticated user")
    }
}
