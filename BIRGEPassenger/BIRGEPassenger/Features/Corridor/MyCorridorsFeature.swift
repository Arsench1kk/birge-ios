import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct MyCorridorsFeature {
    @ObservableState
    struct State: Equatable {
        var bookings: [CorridorBookingItemDTO] = []
        var isLoading = false
        var errorMessage: String?

        var isEmpty: Bool {
            !isLoading && bookings.isEmpty
        }
    }

    enum Action: Equatable, Sendable {
        case onAppear
        case bookingsLoaded(CorridorBookingsListResponse)
        case bookingsFailed(String)
        case bookingTapped(CorridorBookingItemDTO)
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            case corridorSelected(CorridorOption)
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let response = try await apiClient.fetchCorridorBookings()
                        await send(.bookingsLoaded(response))
                    } catch {
                        await send(.bookingsFailed(error.localizedDescription))
                    }
                }

            case .bookingsLoaded(let response):
                state.isLoading = false
                state.bookings = response.bookings
                return .none

            case .bookingsFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .bookingTapped(let booking):
                return .send(.delegate(.corridorSelected(CorridorOption(dto: booking.corridor))))

            case .delegate:
                return .none
            }
        }
    }
}
