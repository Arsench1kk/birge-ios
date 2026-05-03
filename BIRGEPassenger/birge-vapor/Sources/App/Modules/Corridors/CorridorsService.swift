import Fluent
import Vapor

struct CorridorsService {
    let req: Request

    func list() async throws -> CorridorListDTO {
        try await seedDefaultsIfNeeded()

        let corridors = try await Corridor.query(on: req.db)
            .filter(\.$isActive == true)
            .sort(\.$matchPercent, .descending)
            .sort(\.$departure)
            .all()
            .map(CorridorDTO.init)

        return CorridorListDTO(corridors: corridors)
    }

    func book(corridorID: UUID) async throws -> CorridorBookingDTO {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can book corridors")
        }

        let passengerID = try req.authenticatedUserID

        if let existingBooking = try await CorridorBooking.query(on: req.db)
            .filter(\.$corridor.$id == corridorID)
            .filter(\.$passenger.$id == passengerID)
            .filter(\.$status != "cancelled")
            .first(),
           let corridor = try await Corridor.find(corridorID, on: req.db) {
            return try CorridorBookingDTO(
                corridor: CorridorDTO(corridor: corridor),
                message: "Corridor already booked",
                bookingID: existingBooking.requireID()
            )
        }

        guard let corridor = try await Corridor.find(corridorID, on: req.db) else {
            throw Abort(.notFound, reason: "Corridor not found")
        }

        guard corridor.isActive else {
            throw Abort(.conflict, reason: "Corridor is not active")
        }

        guard corridor.seatsLeft > 0 else {
            throw Abort(.conflict, reason: "Corridor is full")
        }

        let booking = CorridorBooking(
            corridorID: corridorID,
            passengerID: passengerID
        )
        try await booking.save(on: req.db)

        corridor.seatsLeft -= 1
        try await corridor.save(on: req.db)

        return try CorridorBookingDTO(
            corridor: CorridorDTO(corridor: corridor),
            message: "Corridor booked",
            bookingID: booking.requireID()
        )
    }

    private func seedDefaultsIfNeeded() async throws {
        let count = try await Corridor.query(on: req.db).count()
        guard count == 0 else { return }

        for corridor in Self.defaultCorridors {
            try await corridor.save(on: req.db)
        }
    }

    private static let defaultCorridors = [
        Corridor(
            name: "Алатау → Есентай",
            originName: "Алатау, пр. Аль-Фараби 21",
            destinationName: "Есентай Парк, 77/8",
            originLat: 43.2369,
            originLng: 76.8897,
            destinationLat: 43.2187,
            destinationLng: 76.9286,
            departure: "07:30 утром",
            timeOfDay: "morning",
            seatsLeft: 1,
            seatsTotal: 4,
            priceTenge: 890,
            matchPercent: 98,
            passengerInitials: ["А", "М", "Д"]
        ),
        Corridor(
            name: "Бостандык → Алмалы",
            originName: "Бостандык, ул. Розыбакиева 247",
            destinationName: "Алмалы, ул. Абая 52",
            originLat: 43.2218,
            originLng: 76.8936,
            destinationLat: 43.2472,
            destinationLng: 76.9278,
            departure: "08:00 утром",
            timeOfDay: "morning",
            seatsLeft: 2,
            seatsTotal: 4,
            priceTenge: 750,
            matchPercent: 87,
            passengerInitials: ["К", "Н"]
        ),
        Corridor(
            name: "Орбита → Достык",
            originName: "Орбита-3, Навои 208",
            destinationName: "Достык Плаза",
            originLat: 43.1983,
            originLng: 76.8689,
            destinationLat: 43.2394,
            destinationLng: 76.9566,
            departure: "08:30 утром",
            timeOfDay: "morning",
            seatsLeft: 3,
            seatsTotal: 4,
            priceTenge: 580,
            matchPercent: 74,
            passengerInitials: ["Т"]
        ),
        Corridor(
            name: "Самал → Mega",
            originName: "Самал-2",
            destinationName: "Mega Center Alma-Ata",
            originLat: 43.2335,
            originLng: 76.9571,
            destinationLat: 43.2010,
            destinationLng: 76.8925,
            departure: "18:10 вечером",
            timeOfDay: "evening",
            seatsLeft: 2,
            seatsTotal: 4,
            priceTenge: 820,
            matchPercent: 83,
            passengerInitials: ["Р", "С"]
        )
    ]
}
