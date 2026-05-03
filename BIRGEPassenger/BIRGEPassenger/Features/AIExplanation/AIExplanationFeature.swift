import ComposableArchitecture
import Foundation

@Reducer
struct AIExplanationFeature {
    @ObservableState
    struct State: Equatable {
        var analyzedRoutes = 847
        var radiusMeters = 500
        var timeWindowMinutes = 15
        var sampleRoute = "Алатау -> Есентай"
        var sampleDeparture = "07:30"
        var samplePrice = 890
        var regularTaxiPrice = 1_850
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View: Sendable {
            case tryCorridorsTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case openCorridorList
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .view(.tryCorridorsTapped):
                return .send(.delegate(.openCorridorList))
            case .delegate:
                return .none
            }
        }
    }
}
