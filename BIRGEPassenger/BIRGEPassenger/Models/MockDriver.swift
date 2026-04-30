import Foundation

struct MockDriver: Equatable, Sendable {
    let id: String
    let name: String
    let rating: Double
    let car: String
    let carColor: String
    let plate: String
    let etaMinutes: Int

    static let mock = MockDriver(
        id: "d001",
        name: "Азамат К.",
        rating: 4.92,
        car: "Toyota Camry",
        carColor: "Белый",
        plate: "777 AAA 02",
        etaMinutes: 4
    )
}
