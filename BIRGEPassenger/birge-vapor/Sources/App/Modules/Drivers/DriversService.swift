import Fluent
import Vapor

struct DriversService {
    let req: Request

    func me() async throws -> DriverProfileDTO {
        let (user, profile) = try await driverUserAndProfile()
        return try DriverProfileDTO(user: user, profile: profile)
    }

    func updateMe(dto: UpdateDriverProfileDTO) async throws -> DriverProfileDTO {
        let (user, profile) = try await driverUserAndProfile()

        profile.firstName = normalized(dto.firstName)
        profile.lastName = normalized(dto.lastName)
        profile.birthDate = normalized(dto.birthDate)
        profile.iin = normalized(dto.iin)
        profile.vehicleMake = normalized(dto.vehicleMake)
        profile.vehicleModel = normalized(dto.vehicleModel)
        profile.vehicleYear = normalized(dto.vehicleYear)
        profile.licensePlate = normalized(dto.licensePlate)?.uppercased()
        profile.vehicleColor = normalized(dto.vehicleColor)
        profile.seats = dto.seats
        profile.uploadedDocuments = dto.uploadedDocuments ?? profile.uploadedDocuments
        profile.subscriptionTier = normalized(dto.subscriptionTier)
        profile.kycStatus = (profile.uploadedDocuments?.count ?? 0) >= 3 ? "review" : "draft"

        let fullName = [profile.firstName, profile.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !fullName.isEmpty {
            user.name = fullName
            try await user.save(on: req.db)
        }

        try await profile.save(on: req.db)
        return try DriverProfileDTO(user: user, profile: profile)
    }

    func todayCorridors() async throws -> DriverTodayCorridorsDTO {
        _ = try await driverUserAndProfile()

        let corridors = try await Corridor.query(on: req.db)
            .filter(\.$isActive == true)
            .sort(\.$departure)
            .limit(4)
            .all()

        let items = try corridors.map { try DriverTodayCorridorDTO(corridor: $0) }
        return DriverTodayCorridorsDTO(
            corridors: items,
            todayEarningsEstimate: items.reduce(0) { $0 + $1.estimatedEarnings }
        )
    }

    private func driverUserAndProfile() async throws -> (User, DriverProfile) {
        guard try req.authenticatedUserRole == User.UserRole.driver.rawValue else {
            throw Abort(.forbidden, reason: "Only drivers can access driver profile")
        }

        guard let user = try await User.find(try req.authenticatedUserID, on: req.db) else {
            throw Abort(.notFound, reason: "Driver user not found")
        }

        let userID = try user.requireID()
        if let profile = try await DriverProfile.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() {
            return (user, profile)
        }

        let profile = DriverProfile(
            userID: userID,
            kycStatus: "draft"
        )
        try await profile.save(on: req.db)
        return (user, profile)
    }

    private func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == true ? nil : trimmed
    }
}
