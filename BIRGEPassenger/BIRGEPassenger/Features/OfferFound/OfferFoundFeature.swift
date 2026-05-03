import ComposableArchitecture
import Foundation

private enum OfferFoundCancelID {
    static let countdown = "OfferFoundFeature.countdown"
}

@Reducer
struct OfferFoundFeature {
    @ObservableState
    struct State: Equatable {
        var rideId: String
        var driverInfo: SearchingFeature.DriverInfo
        var secondsRemaining = 45
        var isConfirming = false

        var originTitle = "Алатау, пр. Аль-Фараби 21"
        var destinationTitle = "Есентай Парк, 77/8"
        var departureTime = "07:30"
        var durationText = "~35 мин"
        var fare = 890
        var seatsText = "3 / 4"
        var matchPercent = 98
        var companions = ["Асан", "Мади", "Динара"]
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case countdownTicked
        case delegate(Delegate)

        @CasePathable
        enum View: Sendable {
            case onAppear
            case onDisappear
            case confirmTapped
            case declineTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case confirmed(rideID: String, SearchingFeature.DriverInfo)
            case declined
            case expired
        }
    }

    @Dependency(\.continuousClock) var clock

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                let clock = self.clock
                return .run { send in
                    while !Task.isCancelled {
                        try await clock.sleep(for: .seconds(1))
                        await send(.countdownTicked)
                    }
                }
                .cancellable(id: OfferFoundCancelID.countdown, cancelInFlight: true)

            case .view(.onDisappear):
                return .cancel(id: OfferFoundCancelID.countdown)

            case .view(.confirmTapped):
                state.isConfirming = true
                return .send(.delegate(.confirmed(
                    rideID: state.rideId,
                    state.driverInfo
                )))

            case .view(.declineTapped):
                return .send(.delegate(.declined))

            case .countdownTicked:
                guard state.secondsRemaining > 0 else {
                    return .none
                }
                state.secondsRemaining -= 1
                if state.secondsRemaining == 0 {
                    return .send(.delegate(.expired))
                }
                return .none

            case .delegate:
                state.isConfirming = false
                return .cancel(id: OfferFoundCancelID.countdown)
            }
        }
    }
}
