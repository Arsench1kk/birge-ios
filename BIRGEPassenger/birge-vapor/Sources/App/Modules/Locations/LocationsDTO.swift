import Vapor

struct LocationBulkDTO: Content {
    let rideID: String
    let records: [LocationRecordDTO]

    enum CodingKeys: String, CodingKey {
        case rideID = "ride_id"
        case records
    }
}

struct LocationRecordDTO: Content {
    let latitude: Double
    let longitude: Double
    let timestamp: Double
    let accuracy: Double?
}

struct LocationBulkResponseDTO: Content {
    let message: String
    let count: Int
}

struct RideLocationBroadcastDTO: Content, Equatable {
    let event: String
    let rideID: String
    let payload: Payload
    let timestampMs: Int64

    enum CodingKeys: String, CodingKey {
        case event
        case rideID = "ride_id"
        case payload
        case timestampMs = "timestamp_ms"
    }

    struct Payload: Content, Equatable {
        let lat: Double
        let lng: Double
        let headingDeg: Double?
        let speedKmh: Double?
        let etaSeconds: Int?

        enum CodingKeys: String, CodingKey {
            case lat
            case lng
            case headingDeg = "heading_deg"
            case speedKmh = "speed_kmh"
            case etaSeconds = "eta_seconds"
        }
    }

    init(rideID: String, record: LocationRecordDTO, etaSeconds: Int? = nil) {
        self.event = "ride.location_update"
        self.rideID = rideID
        self.payload = Payload(
            lat: record.latitude,
            lng: record.longitude,
            headingDeg: nil,
            speedKmh: nil,
            etaSeconds: etaSeconds
        )
        self.timestampMs = Int64(record.timestamp * 1000)
    }
}
