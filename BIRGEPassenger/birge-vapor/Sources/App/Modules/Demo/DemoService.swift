import Fluent
import Foundation
@preconcurrency import Redis
import Vapor

struct DemoService {
    let req: Request

    private enum DemoSeed {
        static let passengerPhone = "+77770001001"
        static let driverPhone = "+77770001002"
        static let passengerEmail = "demo-passenger@birge.kz"
        static let driverEmail = "demo-driver@birge.kz"
        static let corridorName = "Demo AI Corridor"
        static let paymentEventID = "demo-kaspi-checkout"
    }

    func state() async throws -> DemoStateDTO {
        DemoStateDTO(
            generatedAt: Date(),
            apiBaseURL: Environment.get("BIRGE_API_BASE_URL") ?? "http://localhost:8080/api/v1",
            tables: try await tableSnapshots(),
            redis: await redisSnapshot(),
            ai: try await aiSnapshot()
        )
    }

    func seed() async throws -> DemoStateDTO {
        let passenger = try await demoPassenger()
        let driver = try await demoDriver()
        let passengerID = try passenger.requireID()
        let driverID = try driver.requireID()
        let corridor = try await demoCorridor()
        let corridorID = try corridor.requireID()

        if try await CorridorBooking.query(on: req.db)
            .filter(\.$corridor.$id == corridorID)
            .filter(\.$passenger.$id == passengerID)
            .first() == nil {
            try await CorridorBooking(corridorID: corridorID, passengerID: passengerID).save(on: req.db)
        }

        if try await PassengerSubscription.query(on: req.db)
            .filter(\.$user.$id == passengerID)
            .first() == nil {
            try await PassengerSubscription(userID: passengerID, planID: "commuter").save(on: req.db)
        }

        if try await PaymentEvent.query(on: req.db)
            .filter(\.$eventID == DemoSeed.paymentEventID)
            .first() == nil {
            try await PaymentEvent(
                userID: passengerID,
                eventID: DemoSeed.paymentEventID,
                paymentID: UUID(),
                provider: "kaspi",
                purpose: "subscription",
                amountTenge: 890,
                status: "checkout_created",
                checkoutURL: "redacted-demo-url",
                metadataJSON: "{\"plan_id\":\"commuter\",\"demo\":true}"
            ).save(on: req.db)
        }

        let ride = try await demoRide(passengerID: passengerID, driverID: driverID)
        let rideID = try ride.requireID()

        if try await DriverRideDecision.query(on: req.db)
            .filter(\.$ride.$id == rideID)
            .filter(\.$driver.$id == driverID)
            .first() == nil {
            try await DriverRideDecision(
                rideID: rideID,
                driverID: driverID,
                decision: .accepted
            ).save(on: req.db)
        }

        if try await DriverLocationRecord.query(on: req.db)
            .filter(\.$rideID == rideID.uuidString)
            .count() == 0 {
            try await DriverLocationRecord(
                rideID: rideID.uuidString,
                userID: driverID,
                userRole: "driver",
                latitude: 43.238,
                longitude: 76.945,
                timestamp: Date().timeIntervalSince1970,
                accuracy: 8
            ).save(on: req.db)
        }

        return try await state()
    }

    func reset() async throws -> DemoStateDTO {
        let users = try await User.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$email == DemoSeed.passengerEmail)
                group.filter(\.$email == DemoSeed.driverEmail)
                group.filter(\.$phone == DemoSeed.passengerPhone)
                group.filter(\.$phone == DemoSeed.driverPhone)
            }
            .all()
        let userIDs = try users.map { try $0.requireID() }

        let rides: [Ride]
        if userIDs.isEmpty {
            rides = []
        } else {
            rides = try await Ride.query(on: req.db)
                .group(.or) { group in
                    for userID in userIDs {
                        group.filter(\.$passenger.$id == userID)
                        group.filter(\.$driver.$id == userID)
                    }
                }
                .all()
        }
        let rideIDs = try rides.map { try $0.requireID() }

        for rideID in rideIDs {
            try await DriverRideDecision.query(on: req.db)
                .filter(\.$ride.$id == rideID)
                .delete()
            try await DriverLocationRecord.query(on: req.db)
                .filter(\.$rideID == rideID.uuidString)
                .delete()
        }
        for userID in userIDs {
            try await PaymentEvent.query(on: req.db)
                .filter(\.$user.$id == userID)
                .delete()
            try await PassengerSubscription.query(on: req.db)
                .filter(\.$user.$id == userID)
                .delete()
            try await CorridorBooking.query(on: req.db)
                .filter(\.$passenger.$id == userID)
                .delete()
            try await DriverProfile.query(on: req.db)
                .filter(\.$user.$id == userID)
                .delete()
        }
        for ride in rides {
            try await ride.delete(on: req.db)
        }
        for user in users {
            try await user.delete(on: req.db)
        }
        try await PaymentEvent.query(on: req.db)
            .filter(\.$eventID == DemoSeed.paymentEventID)
            .delete()

        return try await state()
    }

    private func demoPassenger() async throws -> User {
        if let existing = try await User.query(on: req.db)
            .filter(\.$email == DemoSeed.passengerEmail)
            .first() {
            return existing
        }
        let user = User(
            phone: DemoSeed.passengerPhone,
            email: DemoSeed.passengerEmail,
            passwordHash: try Bcrypt.hash("demo123"),
            role: .passenger,
            name: "Demo Passenger"
        )
        try await user.save(on: req.db)
        return user
    }

    private func demoDriver() async throws -> User {
        let user: User
        if let existing = try await User.query(on: req.db)
            .filter(\.$email == DemoSeed.driverEmail)
            .first() {
            user = existing
        } else {
            user = User(
                phone: DemoSeed.driverPhone,
                email: DemoSeed.driverEmail,
                passwordHash: try Bcrypt.hash("demo123"),
                role: .driver,
                name: "Demo Driver"
            )
            try await user.save(on: req.db)
        }

        let userID = try user.requireID()
        let profile = try await DriverProfile.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() ?? DriverProfile(userID: userID, kycStatus: "review")
        profile.firstName = "Demo"
        profile.lastName = "Driver"
        profile.vehicleMake = "Toyota"
        profile.vehicleModel = "Camry"
        profile.vehicleYear = "2018"
        profile.licensePlate = "777 DEM 02"
        profile.vehicleColor = "Белый"
        profile.seats = 4
        profile.uploadedDocuments = ["driver_license", "vehicle_registration", "selfie"]
        profile.kycStatus = "review"
        profile.subscriptionTier = "professional"
        try await profile.save(on: req.db)
        return user
    }

    private func demoCorridor() async throws -> Corridor {
        if let existing = try await Corridor.query(on: req.db)
            .filter(\.$name == DemoSeed.corridorName)
            .first() {
            return existing
        }
        let corridor = Corridor(
            name: DemoSeed.corridorName,
            originName: "ЖК Алатау",
            destinationName: "Есентай Молл",
            originLat: 43.238,
            originLng: 76.945,
            destinationLat: 43.262,
            destinationLng: 76.912,
            departure: "07:30",
            timeOfDay: "morning",
            seatsLeft: 2,
            seatsTotal: 4,
            priceTenge: 890,
            matchPercent: 98,
            passengerInitials: ["Д", "А", "М"]
        )
        try await corridor.save(on: req.db)
        return corridor
    }

    private func demoRide(passengerID: UUID, driverID: UUID) async throws -> Ride {
        if let existing = try await Ride.query(on: req.db)
            .filter(\.$passenger.$id == passengerID)
            .filter(\.$driver.$id == driverID)
            .first() {
            return existing
        }
        let ride = Ride(
            passengerID: passengerID,
            driverID: driverID,
            status: .driverAccepted,
            originLat: 43.238,
            originLng: 76.945,
            destLat: 43.262,
            destLng: 76.912,
            originName: "ЖК Алатау",
            destinationName: "Есентай Молл",
            tier: "shared",
            fareTenge: 1850
        )
        try await ride.save(on: req.db)
        return ride
    }
}

private extension DemoService {
    func tableSnapshots() async throws -> [DemoTableSnapshotDTO] {
        [
            try await usersSnapshot(),
            try await ridesSnapshot(),
            try await driverProfilesSnapshot(),
            try await corridorsSnapshot(),
            try await corridorBookingsSnapshot(),
            try await subscriptionsSnapshot(),
            try await paymentEventsSnapshot(),
            try await locationRecordsSnapshot(),
            try await driverDecisionsSnapshot()
        ]
    }

    func usersSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await User.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .limit(5)
            .all()
            .map { user in
                DemoTableRowDTO(
                    primary: id(user.id),
                    secondary: "\(user.role.rawValue) · \(user.phone)",
                    fields: [
                        .init(key: "name", value: value(user.name)),
                        .init(key: "email", value: value(user.email)),
                        .init(key: "password_hash", value: "redacted"),
                        .init(key: "created_at", value: date(user.createdAt))
                    ]
                )
            }
        return try await snapshot(
            name: User.schema,
            explanation: "Пассажиры и водители. Создаются через OTP или email registration.",
            source: "AuthService: OTP/register/login",
            rows: rows,
            count: User.query(on: req.db).count()
        )
    }

    func ridesSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await Ride.query(on: req.db)
            .sort(\.$requestedAt, .descending)
            .limit(5)
            .all()
            .map { ride in
                DemoTableRowDTO(
                    primary: id(ride.id),
                    secondary: "\(ride.status.rawValue) · \(value(ride.tier))",
                    fields: [
                        .init(key: "passenger_id", value: ride.$passenger.id.uuidString),
                        .init(key: "driver_id", value: ride.$driver.id?.uuidString ?? "nil"),
                        .init(key: "origin", value: value(ride.originName)),
                        .init(key: "destination", value: value(ride.destinationName)),
                        .init(key: "fare_tenge", value: int(ride.fareTenge)),
                        .init(key: "requested_at", value: date(ride.requestedAt))
                    ]
                )
            }
        return try await snapshot(
            name: Ride.schema,
            explanation: "Главная поездка: requested -> driver_accepted -> passenger_wait -> in_progress -> completed.",
            source: "Passenger create ride, Driver accept/commands",
            rows: rows,
            count: Ride.query(on: req.db).count()
        )
    }

    func driverProfilesSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await DriverProfile.query(on: req.db)
            .sort(\.$updatedAt, .descending)
            .limit(5)
            .all()
            .map { profile in
                DemoTableRowDTO(
                    primary: id(profile.id),
                    secondary: "\(value(profile.firstName)) \(value(profile.lastName)) · \(profile.kycStatus)",
                    fields: [
                        .init(key: "user_id", value: profile.$user.id.uuidString),
                        .init(key: "vehicle", value: [profile.vehicleMake, profile.vehicleModel, profile.vehicleYear].compactMap { $0 }.joined(separator: " ")),
                        .init(key: "license_plate", value: value(profile.licensePlate)),
                        .init(key: "iin", value: "redacted"),
                        .init(key: "subscription_tier", value: value(profile.subscriptionTier))
                    ]
                )
            }
        return try await snapshot(
            name: DriverProfile.schema,
            explanation: "Анкета водителя: personal data, vehicle, documents, subscription tier.",
            source: "BIRGEDrive registration onboarding",
            rows: rows,
            count: DriverProfile.query(on: req.db).count()
        )
    }

    func corridorsSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await Corridor.query(on: req.db)
            .sort(\.$matchPercent, .descending)
            .limit(5)
            .all()
            .map { corridor in
                DemoTableRowDTO(
                    primary: id(corridor.id),
                    secondary: "\(corridor.name) · \(corridor.matchPercent)%",
                    fields: [
                        .init(key: "route", value: "\(corridor.originName) -> \(corridor.destinationName)"),
                        .init(key: "departure", value: corridor.departure),
                        .init(key: "seats", value: "\(corridor.seatsLeft)/\(corridor.seatsTotal)"),
                        .init(key: "price_tenge", value: "\(corridor.priceTenge)")
                    ]
                )
            }
        return try await snapshot(
            name: Corridor.schema,
            explanation: "AI corridor candidates for shared regular routes.",
            source: "CorridorsService seed/list",
            rows: rows,
            count: Corridor.query(on: req.db).count()
        )
    }

    func corridorBookingsSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await CorridorBooking.query(on: req.db)
            .sort(\.$bookedAt, .descending)
            .limit(5)
            .all()
            .map { booking in
                DemoTableRowDTO(
                    primary: id(booking.id),
                    secondary: booking.status,
                    fields: [
                        .init(key: "corridor_id", value: booking.$corridor.id.uuidString),
                        .init(key: "passenger_id", value: booking.$passenger.id.uuidString),
                        .init(key: "booked_at", value: date(booking.bookedAt))
                    ]
                )
            }
        return try await snapshot(
            name: CorridorBooking.schema,
            explanation: "Факт присоединения пассажира к corridor.",
            source: "POST /api/v1/corridors/:id/book",
            rows: rows,
            count: CorridorBooking.query(on: req.db).count()
        )
    }

    func subscriptionsSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await PassengerSubscription.query(on: req.db)
            .sort(\.$activatedAt, .descending)
            .limit(5)
            .all()
            .map { subscription in
                DemoTableRowDTO(
                    primary: id(subscription.id),
                    secondary: subscription.planID,
                    fields: [
                        .init(key: "user_id", value: subscription.$user.id.uuidString),
                        .init(key: "activated_at", value: date(subscription.activatedAt))
                    ]
                )
            }
        return try await snapshot(
            name: PassengerSubscription.schema,
            explanation: "Активный тариф пассажира.",
            source: "POST /api/v1/subscriptions/activate",
            rows: rows,
            count: PassengerSubscription.query(on: req.db).count()
        )
    }

    func paymentEventsSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await PaymentEvent.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .limit(5)
            .all()
            .map { event in
                DemoTableRowDTO(
                    primary: id(event.id),
                    secondary: "\(event.provider) · \(event.status)",
                    fields: [
                        .init(key: "event_id", value: event.eventID),
                        .init(key: "payment_id", value: event.paymentID.uuidString),
                        .init(key: "amount_tenge", value: "\(event.amountTenge)"),
                        .init(key: "checkout_url", value: event.checkoutURL == nil ? "nil" : "redacted"),
                        .init(key: "created_at", value: date(event.createdAt))
                    ]
                )
            }
        return try await snapshot(
            name: PaymentEvent.schema,
            explanation: "Append-only Kaspi checkout/webhook event log.",
            source: "PaymentsService",
            rows: rows,
            count: PaymentEvent.query(on: req.db).count()
        )
    }

    func locationRecordsSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await DriverLocationRecord.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .limit(5)
            .all()
            .map { record in
                DemoTableRowDTO(
                    primary: id(record.id),
                    secondary: "\(record.userRole) · \(record.rideID)",
                    fields: [
                        .init(key: "user_id", value: record.$user.id.uuidString),
                        .init(key: "lat", value: String(format: "%.5f", record.latitude)),
                        .init(key: "lng", value: String(format: "%.5f", record.longitude)),
                        .init(key: "timestamp", value: String(format: "%.0f", record.timestamp))
                    ]
                )
            }
        return try await snapshot(
            name: DriverLocationRecord.schema,
            explanation: "Offline-first GPS records synced from driver app and broadcast to passenger WebSocket.",
            source: "POST /api/v1/locations/bulk",
            rows: rows,
            count: DriverLocationRecord.query(on: req.db).count()
        )
    }

    func driverDecisionsSnapshot() async throws -> DemoTableSnapshotDTO {
        let rows = try await DriverRideDecision.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .limit(5)
            .all()
            .map { decision in
                DemoTableRowDTO(
                    primary: id(decision.id),
                    secondary: decision.decision.rawValue,
                    fields: [
                        .init(key: "ride_id", value: decision.$ride.id.uuidString),
                        .init(key: "driver_id", value: decision.$driver.id.uuidString),
                        .init(key: "created_at", value: date(decision.createdAt))
                    ]
                )
            }
        return try await snapshot(
            name: DriverRideDecision.schema,
            explanation: "Per-driver accepted/declined state so stale offers do not return.",
            source: "Driver accept/decline endpoints",
            rows: rows,
            count: DriverRideDecision.query(on: req.db).count()
        )
    }

    func redisSnapshot() async -> DemoRedisSnapshotDTO {
        let dbSize = (try? await req.redis.send(command: "DBSIZE", with: []).get())?.int
        async let otpCount = countRedisKeys(matching: "otp:*")
        async let refreshCount = countRedisKeys(matching: "refresh:*")
        async let blacklistCount = countRedisKeys(matching: "blacklist:*")
        let (otpKeys, refreshKeys, blacklistKeys) = await (otpCount, refreshCount, blacklistCount)
        return DemoRedisSnapshotDTO(
            dbSize: dbSize,
            otpKeys: otpKeys,
            refreshKeys: refreshKeys,
            blacklistKeys: blacklistKeys,
            notes: [
                "otp:* stores one-time login codes with a 5 minute TTL.",
                "refresh:* stores active refresh sessions.",
                "blacklist:* stores logged-out access JWT ids until expiry.",
                "Values are intentionally not returned in demo output."
            ]
        )
    }

    func aiSnapshot() async throws -> DemoAISnapshotDTO {
        let corridors = try await Corridor.query(on: req.db)
            .sort(\.$matchPercent, .descending)
            .limit(5)
            .all()
        let candidates = try corridors.map { corridor in
            DemoAICandidateDTO(
                id: try corridor.requireID().uuidString,
                route: "\(corridor.originName) -> \(corridor.destinationName)",
                matchPercent: corridor.matchPercent,
                priceTenge: corridor.priceTenge,
                seatsLeft: corridor.seatsLeft,
                reason: "Route distance, +/-15 min departure window, available seats, and price saving scored this corridor."
            )
        }
        return DemoAISnapshotDTO(
            title: "AI Corridor Matching",
            engine: "Deterministic scoring for route grouping",
            input: [
                .init(key: "origin", value: "ЖК Алатау / nearby pickup radius"),
                .init(key: "destination", value: "Есентай / same direction"),
                .init(key: "timeWindow", value: "+/-15 minutes"),
                .init(key: "seatTarget", value: "2-4 passengers")
            ],
            scoring: [
                .init(key: "distanceRadius", value: "500 m pickup grouping"),
                .init(key: "timeSimilarity", value: "morning/evening commute windows"),
                .init(key: "seatAvailability", value: "prefer corridors with free seats"),
                .init(key: "priceSaving", value: "shared fare vs regular taxi")
            ],
            candidates: candidates,
            explanation: "BIRGE shows this as AI because the app calculates route similarity, timing, capacity and saving scores to form shared corridors without calling an external LLM."
        )
    }

    func countRedisKeys(matching pattern: String) async -> Int? {
        do {
            var cursor = 0
            var total = 0
            repeat {
                let result = try await req.redis.scan(
                    startingFrom: cursor,
                    matching: pattern,
                    count: 100
                ).get()
                cursor = result.0
                total += result.1.count
            } while cursor != 0
            return total
        } catch {
            return nil
        }
    }

    func snapshot(
        name: String,
        explanation: String,
        source: String,
        rows: [DemoTableRowDTO],
        count: EventLoopFuture<Int>
    ) async throws -> DemoTableSnapshotDTO {
        DemoTableSnapshotDTO(
            name: name,
            count: try await count.get(),
            explanation: explanation,
            source: source,
            rows: rows
        )
    }

    func id(_ id: UUID?) -> String {
        id?.uuidString ?? "unsaved"
    }

    func value(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "nil" }
        return value
    }

    func int(_ value: Int?) -> String {
        value.map(String.init) ?? "nil"
    }

    func date(_ date: Date?) -> String {
        guard let date else { return "nil" }
        return ISO8601DateFormatter().string(from: date)
    }
}
