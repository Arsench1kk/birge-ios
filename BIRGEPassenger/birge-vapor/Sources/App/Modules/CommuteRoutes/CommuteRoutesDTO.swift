import Vapor

struct CommuteRoutesDTO {
    struct CreateRouteRequest: Content {
        let originName: String
        let originLat: Double
        let originLng: Double
        let destinationName: String
        let destinationLat: Double
        let destinationLng: Double
        let weekdays: [String]
        let departureWindow: String
    }

    struct RouteResponse: Content {
        let id: UUID
        let originName: String
        let destinationName: String
        let originLat: Double
        let originLng: Double
        let destinationLat: Double
        let destinationLng: Double
        let weekdays: [String]
        let departureWindow: String
        let corridorID: UUID?
        let isActive: Bool
        let createdAt: Date?

        init(route: RecurringRoute) throws {
            self.id = try route.requireID()
            self.originName = route.originName
            self.destinationName = route.destinationName
            self.originLat = route.originLat
            self.originLng = route.originLng
            self.destinationLat = route.destinationLat
            self.destinationLng = route.destinationLng
            self.weekdays = route.weekdays
            self.departureWindow = route.departureWindow
            self.corridorID = route.$corridor.id
            self.isActive = route.isActive
            self.createdAt = route.createdAt
        }
    }

    struct RoutesListResponse: Content {
        let routes: [RouteResponse]
    }
}
