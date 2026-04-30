import Foundation

struct CorridorOption: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let departure: String
    let seatsLeft: Int
    let price: Int

    static let mock: [CorridorOption] = [
        CorridorOption(id: "c1", name: "Алатау → Есентай",
            departure: "07:30", seatsLeft: 3, price: 890),
        CorridorOption(id: "c2", name: "Бостандык → Алмалы",
            departure: "08:00", seatsLeft: 2, price: 750),
    ]
}
