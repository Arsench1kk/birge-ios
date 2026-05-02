import Foundation

public struct CreateRideRequest: Codable, Equatable, Sendable {
    public let originLat: Double
    public let originLng: Double
    public let destinationLat: Double
    public let destinationLng: Double
    public let tier: String

    public init(
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
}

public struct RideDTO: Codable, Equatable, Sendable {
    public let id: UUID
    public let status: String
    public let passengerId: UUID
    public let originLat: Double
    public let originLng: Double
    public let destinationLat: Double
    public let destinationLng: Double
    public let tier: String
    public let estimatedFare: Double?
    public let createdAt: Date

    public let driverId: UUID?
    public let driverName: String?
    public let driverRating: Double?
    public let driverVehicle: String?
    public let driverPlate: String?
    public let etaSeconds: Int?
    public let verificationCode: String?

    public var rideId: String { id.uuidString }
    public var pickupLatitude: Double? { originLat }
    public var pickupLongitude: Double? { originLng }

    public init(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        status: String,
        passengerId: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        originLat: Double = 0,
        originLng: Double = 0,
        destinationLat: Double = 0,
        destinationLng: Double = 0,
        tier: String = "on_demand",
        estimatedFare: Double? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        driverId: UUID? = nil,
        driverName: String? = nil,
        driverRating: Double? = nil,
        driverVehicle: String? = nil,
        driverPlate: String? = nil,
        etaSeconds: Int? = nil,
        verificationCode: String? = nil
    ) {
        self.id = id
        self.status = status
        self.passengerId = passengerId
        self.originLat = originLat
        self.originLng = originLng
        self.destinationLat = destinationLat
        self.destinationLng = destinationLng
        self.tier = tier
        self.estimatedFare = estimatedFare
        self.createdAt = createdAt
        self.driverId = driverId
        self.driverName = driverName
        self.driverRating = driverRating
        self.driverVehicle = driverVehicle
        self.driverPlate = driverPlate
        self.etaSeconds = etaSeconds
        self.verificationCode = verificationCode
    }

    public init(
        rideId: String,
        status: String,
        driverName: String? = nil,
        driverRating: Double? = nil,
        driverVehicle: String? = nil,
        driverPlate: String? = nil,
        etaSeconds: Int? = nil,
        verificationCode: String? = nil,
        pickupLatitude: Double? = nil,
        pickupLongitude: Double? = nil
    ) {
        self.init(
            id: UUID(uuidString: rideId) ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            status: status,
            originLat: pickupLatitude ?? 0,
            originLng: pickupLongitude ?? 0,
            driverName: driverName,
            driverRating: driverRating,
            driverVehicle: driverVehicle,
            driverPlate: driverPlate,
            etaSeconds: etaSeconds,
            verificationCode: verificationCode
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case rideID = "ride_id"
        case status
        case passengerId
        case passengerID = "passenger_id"
        case originLat
        case originLng
        case destinationLat
        case destinationLng
        case destLat
        case destLng
        case tier
        case estimatedFare
        case estimatedFareSnake = "estimated_fare"
        case fareTenge
        case createdAt
        case createdAtSnake = "created_at"
        case requestedAt
        case requestedAtSnake = "requested_at"
        case driverId
        case driverID = "driver_id"
        case driverName = "driver_name"
        case driverRating = "driver_rating"
        case driverVehicle = "driver_vehicle"
        case driverPlate = "driver_plate"
        case etaSeconds = "eta_seconds"
        case verificationCode = "verification_code"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeFlexibleUUID(.id, .rideID)
        self.status = try container.decode(String.self, forKey: .status)
        self.passengerId = try container.decodeFlexibleUUID(.passengerId, .passengerID)
        self.originLat = try container.decode(Double.self, forKey: .originLat)
        self.originLng = try container.decode(Double.self, forKey: .originLng)
        self.destinationLat = try container.decodeIfPresent(Double.self, forKey: .destinationLat)
            ?? container.decode(Double.self, forKey: .destLat)
        self.destinationLng = try container.decodeIfPresent(Double.self, forKey: .destinationLng)
            ?? container.decode(Double.self, forKey: .destLng)
        self.tier = try container.decodeIfPresent(String.self, forKey: .tier) ?? "on_demand"
        self.estimatedFare = try container.decodeIfPresent(Double.self, forKey: .estimatedFare)
            ?? container.decodeIfPresent(Double.self, forKey: .estimatedFareSnake)
            ?? container.decodeIfPresent(Int.self, forKey: .fareTenge).map(Double.init)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
            ?? container.decodeIfPresent(Date.self, forKey: .createdAtSnake)
            ?? container.decodeIfPresent(Date.self, forKey: .requestedAt)
            ?? container.decodeIfPresent(Date.self, forKey: .requestedAtSnake)
            ?? Date(timeIntervalSince1970: 0)
        self.driverId = try container.decodeFlexibleOptionalUUID(.driverId, .driverID)
        self.driverName = try container.decodeIfPresent(String.self, forKey: .driverName)
        self.driverRating = try container.decodeIfPresent(Double.self, forKey: .driverRating)
        self.driverVehicle = try container.decodeIfPresent(String.self, forKey: .driverVehicle)
        self.driverPlate = try container.decodeIfPresent(String.self, forKey: .driverPlate)
        self.etaSeconds = try container.decodeIfPresent(Int.self, forKey: .etaSeconds)
        self.verificationCode = try container.decodeIfPresent(String.self, forKey: .verificationCode)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(status, forKey: .status)
        try container.encode(passengerId, forKey: .passengerId)
        try container.encode(originLat, forKey: .originLat)
        try container.encode(originLng, forKey: .originLng)
        try container.encode(destinationLat, forKey: .destinationLat)
        try container.encode(destinationLng, forKey: .destinationLng)
        try container.encode(tier, forKey: .tier)
        try container.encodeIfPresent(estimatedFare, forKey: .estimatedFare)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(driverId, forKey: .driverId)
        try container.encodeIfPresent(driverName, forKey: .driverName)
        try container.encodeIfPresent(driverRating, forKey: .driverRating)
        try container.encodeIfPresent(driverVehicle, forKey: .driverVehicle)
        try container.encodeIfPresent(driverPlate, forKey: .driverPlate)
        try container.encodeIfPresent(etaSeconds, forKey: .etaSeconds)
        try container.encodeIfPresent(verificationCode, forKey: .verificationCode)
    }
}

public typealias RideResponse = RideDTO
public typealias CreateRideResponse = RideDTO

private extension KeyedDecodingContainer {
    func decodeFlexibleUUID(_ keys: Key...) throws -> UUID {
        for key in keys {
            if let uuid = try decodeIfPresent(UUID.self, forKey: key) {
                return uuid
            }
            if let value = try decodeIfPresent(String.self, forKey: key),
               let uuid = UUID(uuidString: value) {
                return uuid
            }
        }
        throw DecodingError.keyNotFound(
            keys[0],
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected a UUID in one of keys: \(keys.map(\.stringValue).joined(separator: ", "))"
            )
        )
    }

    func decodeFlexibleOptionalUUID(_ keys: Key...) throws -> UUID? {
        for key in keys {
            if let uuid = try decodeIfPresent(UUID.self, forKey: key) {
                return uuid
            }
            if let value = try decodeIfPresent(String.self, forKey: key) {
                return UUID(uuidString: value)
            }
        }
        return nil
    }
}
