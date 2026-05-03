import Vapor

struct CorridorDTO: Content {
    let id: UUID
    let name: String
    let originName: String
    let destinationName: String
    let originLat: Double
    let originLng: Double
    let destinationLat: Double
    let destinationLng: Double
    let departure: String
    let timeOfDay: String
    let seatsLeft: Int
    let seatsTotal: Int
    let price: Int
    let matchPercent: Int
    let passengerInitials: [String]

    init(corridor: Corridor) throws {
        self.id = try corridor.requireID()
        self.name = corridor.name
        self.originName = corridor.originName
        self.destinationName = corridor.destinationName
        self.originLat = corridor.originLat
        self.originLng = corridor.originLng
        self.destinationLat = corridor.destinationLat
        self.destinationLng = corridor.destinationLng
        self.departure = corridor.departure
        self.timeOfDay = corridor.timeOfDay
        self.seatsLeft = corridor.seatsLeft
        self.seatsTotal = corridor.seatsTotal
        self.price = corridor.priceTenge
        self.matchPercent = corridor.matchPercent
        self.passengerInitials = corridor.passengerInitials
    }
}

struct CorridorListDTO: Content {
    let corridors: [CorridorDTO]
    let aiSummary: String

    init(corridors: [CorridorDTO]) {
        self.corridors = corridors
        self.aiSummary = "AI нашёл \(corridors.count) коридоров по вашим маршрутам"
    }
}

struct CorridorBookingDTO: Content {
    let corridor: CorridorDTO
    let message: String
    let bookingID: UUID?
}

struct CorridorBookingItemDTO: Content {
    let bookingID: UUID
    let status: String
    let bookedAt: Date?
    let corridor: CorridorDTO
}

struct CorridorBookingsListDTO: Content {
    let bookings: [CorridorBookingItemDTO]
}
