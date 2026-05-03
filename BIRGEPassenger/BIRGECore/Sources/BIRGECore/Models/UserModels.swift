import Foundation

public struct UserDTO: Codable, Equatable, Sendable {
    public let id: UUID
    public let phone: String
    public let name: String?
    public let rating: Double
    public let totalRides: Int
    public let createdAt: Date

    public init(
        id: UUID,
        phone: String,
        name: String? = nil,
        rating: Double,
        totalRides: Int,
        createdAt: Date
    ) {
        self.id = id
        self.phone = phone
        self.name = name
        self.rating = rating
        self.totalRides = totalRides
        self.createdAt = createdAt
    }
}
