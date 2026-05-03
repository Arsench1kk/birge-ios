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
