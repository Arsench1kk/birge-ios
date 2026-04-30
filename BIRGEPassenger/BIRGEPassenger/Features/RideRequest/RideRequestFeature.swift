import ComposableArchitecture

@Reducer struct RideRequestFeature {
    @ObservableState
    struct State: Equatable {
        var origin: String = "ЖК Алатау, пр. Аль-Фараби"
        var destination: String = ""
        var selectedTier: RideTier = .standard
        var fares: [RideTier: Int] = [
            .standard: 1850,
            .corridor: 890,
            .comfort: 2400
        ]
        var fare: Int { fares[selectedTier] ?? 0 }
    }

    enum RideTier: String, Equatable, CaseIterable, Sendable {
        case standard = "Стандарт"
        case corridor = "Коридор"
        case comfort = "Комфорт"
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View: Sendable {
            case destinationChanged(String)
            case tierSelected(RideTier)
            case findDriverTapped
            case backTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case rideRequested
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.destinationChanged(let destination)):
                state.destination = destination
                return .none
            case .view(.tierSelected(let tier)):
                state.selectedTier = tier
                return .none
            case .view(.findDriverTapped):
                return .send(.delegate(.rideRequested))
            case .view(.backTapped):
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
