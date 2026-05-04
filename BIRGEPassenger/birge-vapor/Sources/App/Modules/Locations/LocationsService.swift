import Fluent
import Vapor

struct LocationsService {
    let req: Request

    func uploadBulk(dto: LocationBulkDTO) async throws -> LocationBulkResponseDTO {
        let rideID = dto.rideID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rideID.isEmpty else {
            throw Abort(.badRequest, reason: "ride_id is required")
        }

        guard !dto.records.isEmpty else {
            return LocationBulkResponseDTO(message: "No locations to sync", count: 0)
        }

        guard dto.records.count <= 200 else {
            throw Abort(.payloadTooLarge, reason: "Maximum 200 location records per batch")
        }

        let userID = try req.authenticatedUserID
        let role = try req.authenticatedUserRole

        let records = try dto.records.map { record in
            try validate(record)
            return DriverLocationRecord(
                rideID: rideID,
                userID: userID,
                userRole: role,
                latitude: record.latitude,
                longitude: record.longitude,
                timestamp: record.timestamp,
                accuracy: record.accuracy
            )
        }

        try await records.create(on: req.db)
        try await broadcastLatestLocation(rideID: rideID, records: dto.records)
        return LocationBulkResponseDTO(message: "Locations synced", count: records.count)
    }

    private func validate(_ record: LocationRecordDTO) throws {
        guard (-90...90).contains(record.latitude) else {
            throw Abort(.badRequest, reason: "Invalid latitude")
        }

        guard (-180...180).contains(record.longitude) else {
            throw Abort(.badRequest, reason: "Invalid longitude")
        }

        guard record.timestamp > 0 else {
            throw Abort(.badRequest, reason: "Invalid timestamp")
        }

        if let accuracy = record.accuracy, accuracy < 0 {
            throw Abort(.badRequest, reason: "Invalid accuracy")
        }
    }

    private func broadcastLatestLocation(
        rideID: String,
        records: [LocationRecordDTO]
    ) async throws {
        guard let latest = records.max(by: { $0.timestamp < $1.timestamp }) else {
            return
        }

        let payload = RideLocationBroadcastDTO(
            rideID: rideID,
            record: latest,
            etaSeconds: nil
        )
        let data = try JSONEncoder().encode(payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Could not encode location update event")
        }

        await req.application.wsHub.broadcast(to: "ride/\(rideID)", text: text)
    }
}
