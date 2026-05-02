import Vapor

struct CoordinateDTO: Content {
    let lat: Double
    let lng: Double
}

struct CreateRideDTO: Content {
    let originLat: Double
    let originLng: Double
    let destinationLat: Double
    let destinationLng: Double
    let tier: String

    static let allowedTiers: Set<String> = ["on_demand", "shared", "subscription"]

    init(
        originLat: Double,
        originLng: Double,
        destinationLat: Double,
        destinationLng: Double,
        tier: String
    ) {
        self.originLat = originLat
        self.originLng = originLng
        self.destinationLat = destinationLat
        self.destinationLng = destinationLng
        self.tier = tier
    }

    private enum CodingKeys: String, CodingKey {
        case originLat
        case originLng
        case destinationLat
        case destinationLng
        case origin
        case destination
        case tier
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let originLat = try container.decodeIfPresent(Double.self, forKey: .originLat),
           let originLng = try container.decodeIfPresent(Double.self, forKey: .originLng),
           let destinationLat = try container.decodeIfPresent(Double.self, forKey: .destinationLat),
           let destinationLng = try container.decodeIfPresent(Double.self, forKey: .destinationLng) {
            self.originLat = originLat
            self.originLng = originLng
            self.destinationLat = destinationLat
            self.destinationLng = destinationLng
            self.tier = try container.decode(String.self, forKey: .tier)
            return
        }

        let origin = try container.decode(CoordinateDTO.self, forKey: .origin)
        let destination = try container.decode(CoordinateDTO.self, forKey: .destination)
        self.originLat = origin.lat
        self.originLng = origin.lng
        self.destinationLat = destination.lat
        self.destinationLng = destination.lng

        if let tier = try? container.decode(String.self, forKey: .tier) {
            self.tier = tier
        } else {
            let tier = try container.decodeIfPresent(Int.self, forKey: .tier)
            self.tier = Self.apiTier(fromLegacyTier: tier)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(originLat, forKey: .originLat)
        try container.encode(originLng, forKey: .originLng)
        try container.encode(destinationLat, forKey: .destinationLat)
        try container.encode(destinationLng, forKey: .destinationLng)
        try container.encode(tier, forKey: .tier)
    }

    private static func apiTier(fromLegacyTier tier: Int?) -> String {
        switch tier {
        case 2:
            "shared"
        case 3:
            "subscription"
        default:
            "on_demand"
        }
    }
}

struct RideDTO: Content {
    let id: UUID
    let status: String
    let passengerId: UUID
    let originLat: Double
    let originLng: Double
    let destinationLat: Double
    let destinationLng: Double
    let tier: String
    let estimatedFare: Double?
    let createdAt: Date
    let driverId: UUID?

    init(ride: Ride) throws {
        self.id = try ride.requireID()
        self.status = ride.status.rawValue
        self.passengerId = ride.$passenger.id
        self.originLat = ride.originLat
        self.originLng = ride.originLng
        self.destinationLat = ride.destLat
        self.destinationLng = ride.destLng
        self.tier = ride.tier ?? "on_demand"
        self.estimatedFare = ride.fareTenge.map(Double.init)
        self.createdAt = ride.createdAt ?? ride.requestedAt ?? Date()
        self.driverId = ride.$driver.id
    }
}
