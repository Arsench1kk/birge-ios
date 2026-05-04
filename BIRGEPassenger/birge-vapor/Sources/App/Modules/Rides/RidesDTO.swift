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
    let originName: String?
    let destinationName: String?
    let tier: String

    static let allowedTiers: Set<String> = ["on_demand", "shared", "subscription"]

    init(
        originLat: Double,
        originLng: Double,
        destinationLat: Double,
        destinationLng: Double,
        originName: String? = nil,
        destinationName: String? = nil,
        tier: String
    ) {
        self.originLat = originLat
        self.originLng = originLng
        self.destinationLat = destinationLat
        self.destinationLng = destinationLng
        self.originName = originName
        self.destinationName = destinationName
        self.tier = tier
    }

    private enum CodingKeys: String, CodingKey {
        case originLat
        case originLng
        case destinationLat
        case destinationLng
        case originName
        case originNameSnake = "origin_name"
        case destinationName
        case destinationNameSnake = "destination_name"
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
            self.originName = try container.decodeIfPresent(String.self, forKey: .originName)
                ?? container.decodeIfPresent(String.self, forKey: .originNameSnake)
            self.destinationName = try container.decodeIfPresent(String.self, forKey: .destinationName)
                ?? container.decodeIfPresent(String.self, forKey: .destinationNameSnake)
            self.tier = try container.decode(String.self, forKey: .tier)
            return
        }

        let origin = try container.decode(CoordinateDTO.self, forKey: .origin)
        let destination = try container.decode(CoordinateDTO.self, forKey: .destination)
        self.originLat = origin.lat
        self.originLng = origin.lng
        self.destinationLat = destination.lat
        self.destinationLng = destination.lng
        self.originName = try container.decodeIfPresent(String.self, forKey: .originName)
            ?? container.decodeIfPresent(String.self, forKey: .originNameSnake)
        self.destinationName = try container.decodeIfPresent(String.self, forKey: .destinationName)
            ?? container.decodeIfPresent(String.self, forKey: .destinationNameSnake)

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
        try container.encodeIfPresent(originName, forKey: .originName)
        try container.encodeIfPresent(destinationName, forKey: .destinationName)
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
    let originName: String?
    let destinationName: String?
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
        self.originName = ride.originName
        self.destinationName = ride.destinationName
        self.tier = ride.tier ?? "on_demand"
        self.estimatedFare = ride.fareTenge.map(Double.init)
        self.createdAt = ride.createdAt ?? ride.requestedAt ?? Date()
        self.driverId = ride.$driver.id
    }
}

struct DriverRideOffersDTO: Content, Equatable {
    let offers: [DriverRideOfferDTO]
}

struct DriverRideOfferDTO: Content, Equatable {
    let rideID: UUID
    let passengerName: String
    let pickup: String
    let destination: String
    let fare: Int
    let distanceKm: Double
    let etaMinutes: Int
    let status: String

    init(ride: Ride, passenger: User? = nil) throws {
        self.rideID = try ride.requireID()
        self.passengerName = passenger?.name ?? "Пассажир BIRGE"
        self.pickup = Self.label(
            ride.originName,
            fallbackPrefix: "Подача",
            lat: ride.originLat,
            lng: ride.originLng
        )
        self.destination = Self.label(
            ride.destinationName,
            fallbackPrefix: "Назначение",
            lat: ride.destLat,
            lng: ride.destLng
        )
        self.fare = ride.fareTenge ?? Self.estimatedFare(for: ride)
        self.distanceKm = Self.distanceKm(for: ride)
        self.etaMinutes = Self.etaMinutes(for: ride.status)
        self.status = ride.status.rawValue
    }

    private static func estimatedFare(for ride: Ride) -> Int {
        switch ride.tier {
        case "subscription": 2400
        case "shared": 1850
        default: 2100
        }
    }

    static func etaMinutes(for status: Ride.RideStatus) -> Int {
        switch status {
        case .requested, .matched, .driverAccepted, .driverArriving: 6
        case .passengerWait: 35
        case .inProgress: 28
        case .completed, .cancelled: 0
        }
    }

    private static func distanceKm(for ride: Ride) -> Double {
        let latKm = (ride.destLat - ride.originLat) * 111.0
        let lngKm = (ride.destLng - ride.originLng) * 85.0
        return max(1.0, (latKm * latKm + lngKm * lngKm).squareRoot())
    }

    private static func label(_ value: String?, fallbackPrefix: String, lat: Double, lng: Double) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        return "\(fallbackPrefix): \(String(format: "%.4f", lat)), \(String(format: "%.4f", lng))"
    }
}

struct RideStatusBroadcastDTO: Content, Equatable {
    let event: String
    let rideID: String
    let payload: Payload
    let timestampMs: Int64

    struct Payload: Content, Equatable {
        let status: String
        let etaSeconds: Int?
        let verificationCode: String?
        let driverName: String?
        let driverRating: Double?
        let driverVehicle: String?
        let driverPlate: String?

        private enum CodingKeys: String, CodingKey {
            case status
            case etaSeconds = "eta_seconds"
            case verificationCode = "verification_code"
            case driverName = "driver_name"
            case driverRating = "driver_rating"
            case driverVehicle = "driver_vehicle"
            case driverPlate = "driver_plate"
        }
    }

    init(ride: Ride, driverProfile: DriverProfile? = nil, driver: User? = nil) throws {
        self.event = "ride.status_changed"
        self.rideID = try ride.requireID().uuidString
        self.payload = Payload(
            status: ride.status.rawValue,
            etaSeconds: DriverRideOfferDTO.etaMinutes(for: ride.status) * 60,
            verificationCode: ride.status == .passengerWait ? "0426" : nil,
            driverName: driver?.name,
            driverRating: 4.9,
            driverVehicle: Self.vehicleTitle(profile: driverProfile),
            driverPlate: driverProfile?.licensePlate
        )
        self.timestampMs = Int64(Date().timeIntervalSince1970 * 1000)
    }

    private static func vehicleTitle(profile: DriverProfile?) -> String? {
        guard let profile else { return nil }
        let parts = [profile.vehicleMake, profile.vehicleModel, profile.vehicleYear]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private enum CodingKeys: String, CodingKey {
        case event
        case rideID = "ride_id"
        case payload
        case timestampMs = "timestamp_ms"
    }
}
