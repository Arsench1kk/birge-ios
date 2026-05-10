import Fluent
import Vapor

struct CommutePlansService {
    let req: Request

    // MARK: - Pricing (placeholder — blocked by BQ-007)

    static func price(for planType: String, routeCount: Int) -> Int {
        // TODO(subscription-pivot): Replace with business-confirmed prices once BQ-007 resolves.
        switch planType {
        case MonthlyCommutePlan.PlanType.soloCorridor.rawValue:
            return 15_000
        case MonthlyCommutePlan.PlanType.multiCorridor.rawValue:
            return 25_000
        case MonthlyCommutePlan.PlanType.flexPack.rawValue:
            return 12_000
        default:
            return 0
        }
    }

    static func flexRidesForPack() -> Int {
        // TODO(subscription-pivot): Confirm pack size once BQ-015 resolves.
        20
    }

    // MARK: - Current Plan

    func currentPlan() async throws -> CommutePlansDTO.PlanStatusResponse {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can view commute plans")
        }

        let userID = try req.authenticatedUserID
        let plan = try await MonthlyCommutePlan.query(on: req.db)
            .filter(\.$passenger.$id == userID)
            .filter(\.$status != MonthlyCommutePlan.PlanStatus.expired.rawValue)
            .filter(\.$status != MonthlyCommutePlan.PlanStatus.cancelled.rawValue)
            .sort(\.$createdAt, .descending)
            .first()

        guard let plan else {
            return CommutePlansDTO.PlanStatusResponse(hasPlan: false, plan: nil)
        }

        let routeIDs = try await CommutePlanRoute.query(on: req.db)
            .filter(\.$plan.$id == plan.requireID())
            .all()
            .map { $0.$recurringRoute.id }

        return try CommutePlansDTO.PlanStatusResponse(
            hasPlan: true,
            plan: CommutePlansDTO.PlanResponse(plan: plan, routeIDs: routeIDs)
        )
    }

    // MARK: - Create Plan

    func create(_ dto: CommutePlansDTO.CreatePlanRequest) async throws -> CommutePlansDTO.PlanResponse {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can create commute plans")
        }

        guard let planType = MonthlyCommutePlan.PlanType(rawValue: dto.planType) else {
            throw Abort(.badRequest, reason: "Invalid plan type. Use: solo_corridor, multi_corridor, or flex_pack")
        }

        // Validate route count
        switch planType {
        case .soloCorridor:
            guard dto.routeIDs.count == 1 else {
                throw Abort(.badRequest, reason: "Solo Corridor requires exactly 1 route")
            }
        case .multiCorridor, .flexPack:
            guard !dto.routeIDs.isEmpty else {
                throw Abort(.badRequest, reason: "At least 1 route required")
            }
        }

        let userID = try req.authenticatedUserID
        let now = Date()
        let calendar = Calendar.current
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now

        let price = Self.price(for: dto.planType, routeCount: dto.routeIDs.count)
        let plan = MonthlyCommutePlan(
            passengerID: userID,
            planType: dto.planType,
            billingPeriodStart: now,
            billingPeriodEnd: endOfMonth,
            priceTenge: price,
            flexRidesTotal: planType == .flexPack ? Self.flexRidesForPack() : nil,
            flexRidesUsed: planType == .flexPack ? 0 : nil
        )

        try await plan.save(on: req.db)

        // Link routes to plan
        let planID = try plan.requireID()
        for routeID in dto.routeIDs {
            let link = CommutePlanRoute(planID: planID, recurringRouteID: routeID)
            try await link.save(on: req.db)
        }

        return try CommutePlansDTO.PlanResponse(plan: plan, routeIDs: dto.routeIDs)
    }

    // MARK: - Cancel Plan

    func cancel() async throws -> CommutePlansDTO.PlanStatusResponse {
        guard try req.authenticatedUserRole == User.UserRole.passenger.rawValue else {
            throw Abort(.forbidden, reason: "Only passengers can manage commute plans")
        }

        let userID = try req.authenticatedUserID
        guard let plan = try await MonthlyCommutePlan.query(on: req.db)
            .filter(\.$passenger.$id == userID)
            .filter(\.$status == MonthlyCommutePlan.PlanStatus.active.rawValue)
            .first() else {
            throw Abort(.notFound, reason: "No active plan to cancel")
        }

        plan.status = MonthlyCommutePlan.PlanStatus.cancelled.rawValue
        try await plan.save(on: req.db)

        return CommutePlansDTO.PlanStatusResponse(hasPlan: false, plan: nil)
    }
}
