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

    static let mock: [CorridorOption] = [
        CorridorOption(
            id: "c1",
            name: "Алатау → Есентай",
            departure: "07:30 утром",
            seatsLeft: 1,
            seatsTotal: 4,
            price: 890,
            matchPercent: 98,
            passengerInitials: ["А", "М", "Д"]
        ),
        CorridorOption(
            id: "c2",
            name: "Бостандык → Алмалы",
            departure: "08:00 утром",
            seatsLeft: 2,
            seatsTotal: 4,
            price: 750,
            matchPercent: 87,
            passengerInitials: ["К", "Н"]
        ),
        CorridorOption(
            id: "c3",
            name: "Орбита → Достык",
            departure: "08:30 утром",
            seatsLeft: 3,
            seatsTotal: 4,
            price: 580,
            matchPercent: 74,
            passengerInitials: ["Т"]
        )
    ]
}
