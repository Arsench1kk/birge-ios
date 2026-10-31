import JWT
import Redis
import Vapor

struct JWTMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let payload = try req.jwt.verify(as: BIRGEJWTPayload.self)
        guard payload.type == .access else {
            throw Abort(.unauthorized, reason: "Invalid token type")
        }

        guard let userID = UUID(uuidString: payload.userID) else {
            throw Abort(.unauthorized, reason: "Invalid user ID")
        }

        let blacklisted = try await req.redis.get(
            RedisKey("blacklist:\(payload.jti)"),
            as: String.self
        ).get()
        guard blacklisted == nil else {
            throw Abort(.unauthorized, reason: "Token revoked")
        }
        if let sessionID = payload.sessionID,
           try await req.redis.get(RedisKey("revoked-session:\(sessionID)"), as: String.self).get() != nil {
            throw Abort(.unauthorized, reason: "Session revoked")
        }

        req.storage[UserIDKey.self] = userID
        req.storage[UserRoleKey.self] = payload.role
        return try await next.respond(to: req)
    }
}
