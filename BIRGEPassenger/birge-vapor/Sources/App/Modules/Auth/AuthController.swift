import Vapor

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        let publicAuth = auth.grouped(RateLimitMiddleware(limit: 10, window: 60))

        publicAuth.post("otp", "request", use: requestOTP)
        publicAuth.post("otp", "verify", use: verifyOTP)
        publicAuth.post("register", use: register)
        publicAuth.post("login", use: login)
        publicAuth.post("refresh", use: refreshToken)

        let protected = auth.grouped(JWTMiddleware())
        protected.post("logout", use: logout)
        protected.get("me", use: me)
    }

    func requestOTP(req: Request) async throws -> HTTPStatus {
        let dto = try req.content.decode(OTPRequestDTO.self)
        try await AuthService(req: req).requestOTP(phone: dto.phone)
        return .ok
    }

    func verifyOTP(req: Request) async throws -> AuthResponseDTO {
        let dto = try req.content.decode(OTPVerifyDTO.self)
        return try await AuthService(req: req).verifyOTP(phone: dto.phone, code: dto.code)
    }

    func register(req: Request) async throws -> AuthResponseDTO {
        let dto = try req.content.decode(EmailRegisterDTO.self)
        return try await AuthService(req: req).register(dto: dto)
    }

    func login(req: Request) async throws -> AuthResponseDTO {
        let dto = try req.content.decode(EmailLoginDTO.self)
        return try await AuthService(req: req).login(email: dto.email, password: dto.password)
    }

    func me(req: Request) async throws -> UserResponseDTO {
        try await AuthService(req: req).getMe()
    }

    func logout(req: Request) async throws -> HTTPStatus {
        try await AuthService(req: req).logout()
        return .ok
    }

    func refreshToken(req: Request) async throws -> AuthResponseDTO {
        try await AuthService(req: req).refresh()
    }
}
