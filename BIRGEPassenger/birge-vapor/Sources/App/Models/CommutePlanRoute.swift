import Fluent
import Vapor

/// Join table linking a MonthlyCommutePlan to its covered RecurringRoutes.
/// Solo Corridor → 1 route, Multi Corridor → N routes, Flex Pack → N routes.
final class CommutePlanRoute: Model, Content, @unchecked Sendable {
    static let schema = "commute_plan_routes"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "plan_id")
    var plan: MonthlyCommutePlan

    @Parent(key: "recurring_route_id")
    var recurringRoute: RecurringRoute

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        planID: UUID,
        recurringRouteID: UUID
    ) {
        self.id = id
        self.$plan.id = planID
        self.$recurringRoute.id = recurringRouteID
    }
}
