import BIRGECore
import Foundation

struct CorridorOption: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let departure: String
    let seatsLeft: Int
    let seatsTotal: Int
    let price: Int
    let matchPercent: Int
    let passengerInitials: [String]
    let originName: String
    let destinationName: String
    let timeOfDay: String

    static let mock: [CorridorOption] = [
        CorridorOption(
            id: "c1",
            name: "Алатау → Есентай",
            departure: "07:30 утром",
            seatsLeft: 1,
            seatsTotal: 4,
            price: 890,
            matchPercent: 98,
            passengerInitials: ["А", "М", "Д"],
            originName: "Алатау, пр. Аль-Фараби 21",
            destinationName: "Есентай Парк, 77/8",
            timeOfDay: "morning"
        ),
        CorridorOption(
            id: "c2",
            name: "Бостандык → Алмалы",
            departure: "08:00 утром",
            seatsLeft: 2,
            seatsTotal: 4,
            price: 750,
            matchPercent: 87,
            passengerInitials: ["К", "Н"],
            originName: "Бостандык, ул. Розыбакиева 247",
            destinationName: "Алмалы, ул. Абая 52",
            timeOfDay: "morning"
        ),
        CorridorOption(
            id: "c3",
            name: "Орбита → Достык",
            departure: "08:30 утром",
            seatsLeft: 3,
            seatsTotal: 4,
            price: 580,
            matchPercent: 74,
            passengerInitials: ["Т"],
            originName: "Орбита-3, Навои 208",
            destinationName: "Достык Плаза",
            timeOfDay: "morning"
        )
    ]
}

extension CorridorOption {
    nonisolated init(dto: CorridorDTO) {
        self.id = dto.id.uuidString
        self.name = dto.name
        self.departure = dto.departure
        self.seatsLeft = dto.seatsLeft
        self.seatsTotal = dto.seatsTotal
        self.price = dto.price
        self.matchPercent = dto.matchPercent
        self.passengerInitials = dto.passengerInitials
        self.originName = dto.originName
        self.destinationName = dto.destinationName
        self.timeOfDay = dto.timeOfDay
    }
}
