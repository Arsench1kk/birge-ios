import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct CorridorDetailFeature {
    @ObservableState
    struct State: Equatable {
        var corridor: CorridorOption
        var isJoining = false
        var isJoined = false
        var bookingID: String?
        var statusMessage: String?
        var errorMessage: String?
    }

    enum Action: Equatable, Sendable {
        case joinTapped
        case joinFinished(CorridorBookingResponse)
        case joinFailed(String)
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            case joined
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .joinTapped:
                state.isJoining = true
                state.errorMessage = nil
                let corridorID = state.corridor.id
                return .run { send in
                    do {
                        let response = try await apiClient.bookCorridor(corridorID)
                        await send(.joinFinished(response))
                        await send(.delegate(.joined))
                    } catch {
                        await send(.joinFailed(error.localizedDescription))
                    }
                }

            case .joinFinished(let response):
                state.isJoining = false
                state.isJoined = true
                state.bookingID = response.bookingID
                state.statusMessage = response.message == "Corridor already booked"
                    ? "Вы уже в этом коридоре"
                    : "Место забронировано"
                state.corridor = CorridorOption(dto: response.corridor)
                return .none

            case .joinFailed(let message):
                state.isJoining = false
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
