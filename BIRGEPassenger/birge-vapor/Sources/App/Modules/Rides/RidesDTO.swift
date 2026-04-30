import Vapor

struct CoordinateDTO: Content {
    let lat: Double
    let lng: Double
}

struct CreateRideDTO: Content {
    let origin: CoordinateDTO
    let destination: CoordinateDTO
    let tier: Int?
}

struct RideResponseDTO: Content {
    let id: String
    let passengerId: String
    let driverId: String?
    let status: String
    let originLat: Double
    let originLng: Double
    let destLat: Double
    let destLng: Double
    let fareTenge: Int?
    let requestedAt: Date?

    init(ride: Ride) throws {
        self.id = try ride.requireID().uuidString
        self.passengerId = ride.$passenger.id.uuidString
        self.driverId = ride.$driver.id?.uuidString
        self.status = ride.status.rawValue
        self.originLat = ride.originLat
        self.originLng = ride.originLng
        self.destLat = ride.destLat
        self.destLng = ride.destLng
        self.fareTenge = ride.fareTenge
        self.requestedAt = ride.requestedAt
    }
}
