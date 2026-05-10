import Vapor

struct CommutePlansDTO {
    struct CreatePlanRequest: Content {
        let planType: String  // solo_corridor, multi_corridor, flex_pack
        let routeIDs: [UUID]
    }

    struct PlanResponse: Content {
        let id: UUID
        let planType: String
        let billingPeriodStart: Date
        let billingPeriodEnd: Date
        let status: String
        let priceTenge: Int
        let flexRidesTotal: Int?
        let flexRidesUsed: Int?
        let routeIDs: [UUID]
        let createdAt: Date?

        init(plan: MonthlyCommutePlan, routeIDs: [UUID]) throws {
            self.id = try plan.requireID()
            self.planType = plan.planType
            self.billingPeriodStart = plan.billingPeriodStart
            self.billingPeriodEnd = plan.billingPeriodEnd
            self.status = plan.status
            self.priceTenge = plan.priceTenge
            self.flexRidesTotal = plan.flexRidesTotal
            self.flexRidesUsed = plan.flexRidesUsed
            self.routeIDs = routeIDs
            self.createdAt = plan.createdAt
        }
    }

    struct PlanStatusResponse: Content {
        let hasPlan: Bool
        let plan: PlanResponse?
    }
}
