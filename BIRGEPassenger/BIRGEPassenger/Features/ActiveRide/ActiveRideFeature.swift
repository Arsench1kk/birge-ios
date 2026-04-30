import ComposableArchitecture
import Foundation

@Reducer struct ActiveRideFeature {
    @ObservableState
    struct State: Equatable {
        var status: RideStatus = .driverArriving
        var driver: MockDriver = .mock
        var etaMinutes: Int = 4
        var driverLat: Double = 43.2180
        var driverLng: Double = 76.8450
        var simulationStep: Int = 0
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case delegate(Delegate)
        case simulationTick

        @CasePathable
        enum View: Sendable {
            case onAppear
            case cancelTapped
            case callDriverTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case rideCompleted
            case cancelled
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .run { send in
                    // Step 1: driver arriving (0-8s)
                    for _ in 0..<8 {
                        try await Task.sleep(for: .seconds(1))
                        await send(.simulationTick)
                    }
                    // Step 2: passenger wait (8-11s)
                    for _ in 0..<3 {
                        try await Task.sleep(for: .seconds(1))
                        await send(.simulationTick)
                    }
                    // Step 3: in progress (11-19s)
                    for _ in 0..<8 {
                        try await Task.sleep(for: .seconds(1))
                        await send(.simulationTick)
                    }
                    // Step 4: completed
                    await send(.delegate(.rideCompleted))
                }

            case .simulationTick:
                state.simulationStep += 1
                switch state.simulationStep {
                case 1...8:
                    state.status = .driverArriving
                    state.etaMinutes = max(0, 4 - state.simulationStep / 2)
                    // Move driver toward pickup
                    state.driverLat += 0.0005
                    state.driverLng += 0.0008
                case 9...11:
                    state.status = .passengerWait
                    state.etaMinutes = 0
                case 12...:
                    state.status = .inProgress
                    state.etaMinutes = max(0, 18 - (state.simulationStep - 11))
                default:
                    break
                }
                return .none

            case .view(.cancelTapped):
                return .send(.delegate(.cancelled))

            case .view(.callDriverTapped):
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
