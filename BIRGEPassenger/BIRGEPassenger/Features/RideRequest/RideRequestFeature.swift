import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer struct RideRequestFeature {
    @ObservableState
    struct State: Equatable {
        var origin: String = "ЖК Алатау, пр. Аль-Фараби"
        var destination: String = ""
        var selectedTier: RideTier = .standard
        var isLoading: Bool = false
        var errorMessage: String?
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
        case rideRequestFailed(String)

        @CasePathable
        enum View: Sendable {
            case destinationChanged(String)
            case tierSelected(RideTier)
            case findDriverTapped
            case backTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case rideRequested(rideID: String)
            case back
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.destinationChanged(let destination)):
                state.destination = destination
                state.errorMessage = nil
                return .none
            case .view(.tierSelected(let tier)):
                state.selectedTier = tier
                state.errorMessage = nil
                return .none
            case .view(.findDriverTapped):
                guard !state.destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.errorMessage = "Введите пункт назначения."
                    return .none
                }
                state.isLoading = true
                state.errorMessage = nil
                let tier = state.selectedTier.apiTier
                return .run { send in
                    do {
                        let response = try await apiClient.createRide(
                            LatLng(latitude: 43.238, longitude: 76.945),
                            LatLng(latitude: 43.262, longitude: 76.912),
                            tier
                        )
                        await send(.delegate(.rideRequested(rideID: response.rideID)))
                    } catch {
                        await send(.rideRequestFailed(error.localizedDescription))
                    }
                }
            case .view(.backTapped):
                return .send(.delegate(.back))
            case .delegate:
                state.isLoading = false
                return .none
            case let .rideRequestFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
    }
}

private extension RideRequestFeature.RideTier {
    var apiTier: Int {
        switch self {
        case .standard:
            return 1
        case .corridor:
            return 2
        case .comfort:
            return 3
        }
    }
}
