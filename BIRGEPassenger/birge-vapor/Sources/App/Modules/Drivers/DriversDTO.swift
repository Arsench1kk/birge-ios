import Vapor

struct DriverProfileDTO: Content, Equatable {
    let userID: UUID
    let name: String?
    let phone: String
    let firstName: String?
    let lastName: String?
    let birthDate: String?
    let iin: String?
    let vehicleMake: String?
    let vehicleModel: String?
    let vehicleYear: String?
    let licensePlate: String?
    let vehicleColor: String?
    let seats: Int?
    let uploadedDocuments: [String]
    let kycStatus: String
    let subscriptionTier: String?

    init(user: User, profile: DriverProfile) throws {
        self.userID = try user.requireID()
        self.name = user.name
        self.phone = user.phone
        self.firstName = profile.firstName
        self.lastName = profile.lastName
        self.birthDate = profile.birthDate
        self.iin = profile.iin
        self.vehicleMake = profile.vehicleMake
        self.vehicleModel = profile.vehicleModel
        self.vehicleYear = profile.vehicleYear
        self.licensePlate = profile.licensePlate
        self.vehicleColor = profile.vehicleColor
        self.seats = profile.seats
        self.uploadedDocuments = profile.uploadedDocuments ?? []
        self.kycStatus = profile.kycStatus
        self.subscriptionTier = profile.subscriptionTier
    }
}

struct UpdateDriverProfileDTO: Content {
    let firstName: String?
    let lastName: String?
    let birthDate: String?
    let iin: String?
    let vehicleMake: String?
    let vehicleModel: String?
    let vehicleYear: String?
    let licensePlate: String?
    let vehicleColor: String?
    let seats: Int?
    let uploadedDocuments: [String]?
    let subscriptionTier: String?
}

struct DriverTodayCorridorDTO: Content, Equatable {
    let id: UUID
    let name: String
    let originName: String
    let destinationName: String
    let departure: String
    let seatsTotal: Int
    let passengerInitials: [String]
    let estimatedEarnings: Int
    let status: String

    init(corridor: Corridor, status: String = "scheduled") throws {
        self.id = try corridor.requireID()
        self.name = corridor.name
        self.originName = corridor.originName
        self.destinationName = corridor.destinationName
        self.departure = corridor.departure
        self.seatsTotal = corridor.seatsTotal
        self.passengerInitials = corridor.passengerInitials
        self.estimatedEarnings = corridor.priceTenge * corridor.seatsTotal
        self.status = status
    }
}

struct DriverTodayCorridorsDTO: Content, Equatable {
    let corridors: [DriverTodayCorridorDTO]
    let todayEarningsEstimate: Int
}
