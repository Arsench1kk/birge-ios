import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct PassengerPlannedRideFeature {
    @ObservableState
    struct State: Equatable {
        var rideID: MockPlannedCommuteRide.ID?
        var plannedRide: MockPlannedCommuteRide?
        var isLoading = false
        var isAdvancing = false
        var errorMessage: String?

        var currentStatus: PlannedRideStatus? {
            plannedRide?.status
        }

        var boardingCode: MockBoardingCode? {
            plannedRide?.boardingCode
        }

        var completedSummary: MockCompletedCommuteSummary? {
            plannedRide?.completedSummary
        }

        init(
            rideID: MockPlannedCommuteRide.ID? = nil,
            plannedRide: MockPlannedCommuteRide? = nil
        ) {
            self.rideID = rideID ?? plannedRide?.id
            self.plannedRide = plannedRide
        }
    }

    enum Action: ViewAction, Equatable, Sendable {
        case view(View)
        case plannedRideLoaded(MockPlannedCommuteRide)
        case plannedRideFailed(String)
        case lifecycleAdvanced(MockPlannedCommuteRide)
        case delegate(Delegate)

        @CasePathable
        enum View: Equatable, Sendable {
            case onAppear
            case advanceMockLifecycleTapped
            case driverArrivedTapped
            case showBoardingCodeTapped
            case boardingConfirmedTapped
            case rideStartedTapped
            case rideCompletedTapped
            case reportIssueTapped
            case supportTapped
            case safetyTapped
            case shareStatusTapped
            case backTapped
            case doneTapped
        }

        @CasePathable
        enum Delegate: Equatable, Sendable {
            case reportIssue(MockPlannedCommuteRide.ID?)
            case support(MockPlannedCommuteRide.ID?)
            case safety(MockPlannedCommuteRide.ID?)
            case shareStatus(MockPlannedCommuteRide.ID?)
            case back
            case done
        }
    }

    @Dependency(\.passengerRouteClient) var passengerRouteClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.isLoading = true
                state.errorMessage = nil
                let rideID = state.rideID
                return .run { send in
                    do {
                        let ride: MockPlannedCommuteRide
                        if let rideID {
                            ride = try await passengerRouteClient.plannedRide(rideID)
                        } else {
                            ride = try await passengerRouteClient.todayPlannedRide()
                        }
                        await send(.plannedRideLoaded(ride))
                    } catch {
                        await send(.plannedRideFailed(error.localizedDescription))
                    }
                }

            case .view(.advanceMockLifecycleTapped):
                guard let status = state.currentStatus,
                      let nextStatus = Self.nextStatus(after: status)
                else { return .none }
                return advanceRide(&state, to: nextStatus)

            case .view(.driverArrivedTapped):
                return advanceRide(&state, to: .driverArrived)

            case .view(.showBoardingCodeTapped):
                return advanceRide(&state, to: .boarding)

            case .view(.boardingConfirmedTapped), .view(.rideStartedTapped):
                return advanceRide(&state, to: .inProgress)

            case .view(.rideCompletedTapped):
                return advanceRide(&state, to: .completed)

            case .view(.reportIssueTapped):
                return .send(.delegate(.reportIssue(state.rideID)))

            case .view(.supportTapped):
                return .send(.delegate(.support(state.rideID)))

            case .view(.safetyTapped):
                return .send(.delegate(.safety(state.rideID)))

            case .view(.shareStatusTapped):
                return .send(.delegate(.shareStatus(state.rideID)))

            case .view(.backTapped):
                return .send(.delegate(.back))

            case .view(.doneTapped):
                return .send(.delegate(.done))

            case let .plannedRideLoaded(ride):
                state.isLoading = false
                state.errorMessage = nil
                state.rideID = ride.id
                state.plannedRide = ride
                return .none

            case let .plannedRideFailed(message):
                state.isLoading = false
                state.isAdvancing = false
                state.errorMessage = message
                return .none

            case let .lifecycleAdvanced(ride):
                state.isAdvancing = false
                state.errorMessage = nil
                state.rideID = ride.id
                state.plannedRide = ride
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func advanceRide(
        _ state: inout State,
        to status: PlannedRideStatus
    ) -> Effect<Action> {
        guard let rideID = state.rideID else { return .none }
        state.isAdvancing = true
        state.errorMessage = nil
        return .run { send in
            do {
                let ride = try await passengerRouteClient.advancePlannedRideStatus(rideID, status)
                await send(.lifecycleAdvanced(ride))
            } catch {
                await send(.plannedRideFailed(error.localizedDescription))
            }
        }
    }

    private static func nextStatus(after status: PlannedRideStatus) -> PlannedRideStatus? {
        switch status {
        case .scheduled, .driverAssigned:
            return .driverEnRoute
        case .driverEnRoute:
            return .driverArrived
        case .driverArrived:
            return .boarding
        case .boarding:
            return .inProgress
        case .inProgress:
            return .completed
        case .completed, .delayed, .replacementAssigned, .pickupChanged, .passengerMissedPickup, .cancelled:
            return nil
        }
    }
}
