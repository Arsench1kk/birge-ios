import Vapor

struct OTPRequestDTO: Content {
    let phone: String
}

struct OTPVerifyDTO: Content {
    let phone: String
    let code: String
}

struct EmailLoginDTO: Content {
    let email: String
    let password: String
}

struct EmailRegisterDTO: Content {
    let email: String
    let password: String
    let phone: String
    let role: String
    let name: String
}

struct RefreshTokenDTO: Content {
    let refreshToken: String
}

struct AuthResponseDTO: Content {
    let accessToken: String
    let refreshToken: String
    let role: String
    let userId: String
}

struct UserResponseDTO: Content, Equatable {
    let id: UUID
    let phone: String
    let email: String?
    let role: String
    let name: String?
    let rating: Double
    let totalRides: Int
    let createdAt: Date

    init(user: User, rating: Double = 0.0, totalRides: Int = 0) throws {
        self.id = try user.requireID()
        self.phone = user.phone
        self.email = user.email
        self.role = user.role.rawValue
        self.name = user.name
        self.rating = rating
        self.totalRides = totalRides
        self.createdAt = user.createdAt ?? Date(timeIntervalSince1970: 0)
    }
}
