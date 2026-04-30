import Vapor

struct UserIDKey: StorageKey {
    typealias Value = UUID
}

struct UserRoleKey: StorageKey {
    typealias Value = String
}

extension Request {
    var authenticatedUserID: UUID {
        get throws {
            guard let userID = self.storage[UserIDKey.self] else {
                throw Abort(.unauthorized, reason: "Missing authenticated user")
            }

            return userID
        }
    }

    var authenticatedUserRole: String {
        get throws {
            guard let role = self.storage[UserRoleKey.self] else {
                throw Abort(.unauthorized, reason: "Missing authenticated role")
            }

            return role
        }
    }
}
