import Fluent
import Foundation
import JWT
import Redis
import Vapor

struct AuthService {
    let req: Request

    private let otpTTL: Int = 300
    private let accessTokenTTL: TimeInterval = 60 * 60
    private let refreshTokenTTL: TimeInterval = 60 * 60 * 24 * 30

    func requestOTP(phone: String) async throws {
        let normalizedPhone = normalizePhone(phone)
        let code = String(format: "%06d", Int.random(in: 0...999999))

        _ = try await req.redis.set(
            RedisKey("otp:\(normalizedPhone)"),
            to: RESPValue(from: code)
        ).get()
        _ = try await req.redis.expire(
            RedisKey("otp:\(normalizedPhone)"),
            after: .seconds(300)
        ).get()

        req.logger.info("OTP generated for \(normalizedPhone): \(code)")
        
        // E2E Test Logging: [YYYY-MM-DD HH:mm:ss] Phone: +7777123456 | OTP: 123456
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let logEntry = "[\(timestamp)] Phone: \(normalizedPhone) | OTP: \(code)\n"
        
        let logPath = "/tmp/birge-otp.log"
        if let data = logEntry.data(using: .utf8) {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: logPath) {
                fileManager.createFile(atPath: logPath, contents: data)
            } else if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                try? fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                try? fileHandle.synchronize() // Flush immediately for E2E speed
                try? fileHandle.close()
            }
        }
    }

    func verifyOTP(phone: String, code: String) async throws -> AuthResponseDTO {
        let normalizedPhone = normalizePhone(phone)
        let key = RedisKey("otp:\(normalizedPhone)")

        let storedCode = try await req.redis.get(key, as: String.self).get()
        guard let stored = storedCode, stored == code else {
            throw Abort(.unauthorized, reason: "Invalid OTP")
        }

        _ = try await req.redis.delete(key).get()

        let user: User
        if let existing = try await User.query(on: req.db)
            .filter(\.$phone == normalizedPhone)
            .first() {
            user = existing
        } else {
            let created = User(phone: normalizedPhone, role: .passenger)
            try await created.save(on: req.db)
            user = created
        }

        return try await issueTokens(for: user)
    }

    func register(dto: EmailRegisterDTO) async throws -> AuthResponseDTO {
        let normalizedEmail = normalizeEmail(dto.email)
        let normalizedPhone = normalizePhone(dto.phone)

        if try await User.query(on: req.db)
            .filter(\.$email == normalizedEmail)
            .first() != nil {
            throw Abort(.conflict, reason: "Email already registered")
        }

        let role = User.UserRole(rawValue: dto.role.lowercased()) ?? .passenger
        let user = User(
            phone: normalizedPhone,
            email: normalizedEmail,
            passwordHash: try Bcrypt.hash(dto.password),
            role: role,
            name: dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        try await user.save(on: req.db)

        if user.role == .driver {
            let profile = DriverProfile(
                userID: try user.requireID(),
                kycStatus: "pending"
            )
            try await profile.save(on: req.db)
        }

        return try await issueTokens(for: user)
    }

    func login(email: String, password: String) async throws -> AuthResponseDTO {
        let normalizedEmail = normalizeEmail(email)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == normalizedEmail)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        guard let passwordHash = user.passwordHash,
              try Bcrypt.verify(password, created: passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        return try await issueTokens(for: user)
    }

    func currentUser() async throws -> User {
        guard let user = try await User.find(try req.authenticatedUserID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        return user
    }

    func getMe() async throws -> UserResponseDTO {
        let user = try await currentUser()
        let userID = try user.requireID()
        let totalRides = try await Ride.query(on: req.db)
            .filter(\.$passenger.$id == userID)
            .count()

        return try UserResponseDTO(
            user: user,
            rating: 0.0,
            totalRides: totalRides
        )
    }

    func logout() async throws {
        let payload = try req.jwt.verify(as: BIRGEJWTPayload.self)
        guard payload.type == .access else {
            throw Abort(.unauthorized, reason: "Invalid token type")
        }

        _ = max(1, Int(payload.expiration.timeIntervalSinceNow))
        _ = try await req.redis.set(
            RedisKey("blacklist:\(payload.jti)"),
            to: RESPValue(from: "1")
        ).get()
        _ = try await req.redis.expire(
            RedisKey("blacklist:\(payload.jti)"),
            after: .seconds(3600)
        ).get()
    }

    func refresh() async throws -> AuthResponseDTO {
        let payload = try decodeRefreshPayload()
        guard payload.type == .refresh else {
            throw Abort(.unauthorized, reason: "Invalid token type")
        }

        let refreshKey = RedisKey("refresh:\(payload.jti)")
        guard try await req.redis.get(refreshKey, as: String.self).get() != nil else {
            throw Abort(.unauthorized, reason: "Refresh token revoked")
        }

        _ = try await req.redis.delete(refreshKey).get()

        guard let userID = UUID(uuidString: payload.userID),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        return try await issueTokens(for: user)
    }

    private func issueTokens(for user: User) async throws -> AuthResponseDTO {
        let userID = try user.requireID().uuidString
        let role = user.role.rawValue

        let accessPayload = BIRGEJWTPayload(
            userID: userID,
            role: role,
            type: .access,
            expiration: Date().addingTimeInterval(accessTokenTTL)
        )
        let refreshPayload = BIRGEJWTPayload(
            userID: userID,
            role: role,
            type: .refresh,
            expiration: Date().addingTimeInterval(refreshTokenTTL)
        )

        let accessToken = try req.jwt.sign(accessPayload)
        let refreshToken = try req.jwt.sign(refreshPayload)

        _ = try await req.redis.set(
            RedisKey("refresh:\(refreshPayload.jti)"),
            to: RESPValue(from: userID)
        ).get()
        _ = try await req.redis.expire(
            RedisKey("refresh:\(refreshPayload.jti)"),
            after: .seconds(Int64(refreshTokenTTL))
        ).get()

        return AuthResponseDTO(
            accessToken: accessToken,
            refreshToken: refreshToken,
            role: role,
            userId: userID
        )
    }

    private func decodeRefreshPayload() throws -> BIRGEJWTPayload {
        if let bearer = req.headers.bearerAuthorization {
            return try req.jwt.verify(bearer.token, as: BIRGEJWTPayload.self)
        }

        if let dto = try? req.content.decode(RefreshTokenDTO.self) {
            return try req.jwt.verify(dto.refreshToken, as: BIRGEJWTPayload.self)
        }

        throw Abort(.badRequest, reason: "Refresh token is required")
    }

    private func normalizePhone(_ phone: String) -> String {
        phone
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

struct BIRGEJWTPayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case userID = "sub"
        case role
        case type
        case expiration = "exp"
        case jti
    }

    enum TokenType: String, Codable, Sendable {
        case access
        case refresh
    }

    var userID: String
    var role: String
    var type: TokenType
    var expiration: Date
    var jti: String

    init(
        userID: String,
        role: String,
        type: TokenType,
        expiration: Date,
        jti: String = UUID().uuidString
    ) {
        self.userID = userID
        self.role = role
        self.type = type
        self.expiration = expiration
        self.jti = jti
    }

    func verify(using signer: JWTSigner) throws {
        guard expiration > Date() else {
            throw JWTError.claimVerificationFailure(name: "exp", reason: "Token expired")
        }
    }
}
