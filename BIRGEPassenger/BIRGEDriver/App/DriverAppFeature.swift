//
//  DriverAppFeature.swift
//  BIRGEDriver
//

import ComposableArchitecture
import Foundation

@Reducer
struct DriverAppFeature {

    // MARK: - Nested Models

    struct RideOffer: Equatable, Sendable {
        var passengerName: String
        var pickup: String
        var destination: String
        var fare: Int
        var distanceKm: Double
        var etaMinutes: Int
    }

    struct DriverActiveRide: Equatable, Sendable {
        var passengerName: String
        var destination: String
        var status: RideStatus

        enum RideStatus: Equatable, Sendable {
            case pickingUp
            case passengerWait
            case inProgress
        }
    }

    struct DriverEarnings: Equatable, Sendable {
        var todayTenge: Int
        var todayRides: Int
        var weekTenge: Int

        static let mock = DriverEarnings(todayTenge: 12500, todayRides: 8, weekTenge: 67000)
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var isOnline: Bool = false
        var currentOffer: RideOffer? = nil
        var activeRide: DriverActiveRide? = nil
        var earnings: DriverEarnings = .mock
        var path = StackState<Path.State>()

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.isOnline == rhs.isOnline &&
            lhs.currentOffer == rhs.currentOffer &&
            lhs.activeRide == rhs.activeRide &&
            lhs.earnings == rhs.earnings
            // Note: intentionally skip path comparison
        }
    }

    // MARK: - Path

    @Reducer
    @CasePathable
    enum Path {
        case earnings(EarningsFeature)
    }

    // MARK: - Action

    enum Action: Sendable {
        case toggleOnline
        case offerAppeared
        case acceptOffer
        case declineOffer
        case arrivedAtPickup
        case startRide
        case completeRide
        case earningsTapped
        case path(StackActionOf<Path>)
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .toggleOnline:
                state.isOnline.toggle()
                if !state.isOnline {
                    // Going offline — clear active state
                    state.currentOffer = nil
                    state.activeRide = nil
                    return .none
                }
                // Going online — simulate offer arriving after 4s
                return .run { send in
                    try await Task.sleep(for: .seconds(4))
                    await send(.offerAppeared)
                }

            case .offerAppeared:
                guard state.isOnline, state.activeRide == nil else { return .none }
                state.currentOffer = RideOffer(
                    passengerName: "Арсен А.",
                    pickup: "Алатау, ул. Момышулы 15",
                    destination: "Есентай Молл",
                    fare: 1850,
                    distanceKm: 7.2,
                    etaMinutes: 6
                )
                return .none

            case .acceptOffer:
                state.currentOffer = nil
                state.activeRide = DriverActiveRide(
                    passengerName: "Арсен А.",
                    destination: "Есентай Молл",
                    status: .pickingUp
                )
                return .none

            case .declineOffer:
                state.currentOffer = nil
                // Wait and show next offer
                return .run { send in
                    try await Task.sleep(for: .seconds(6))
                    await send(.offerAppeared)
                }

            case .arrivedAtPickup:
                state.activeRide?.status = .passengerWait
                return .none

            case .startRide:
                state.activeRide?.status = .inProgress
                return .none

            case .completeRide:
                state.activeRide = nil
                state.earnings.todayTenge += 1850
                state.earnings.todayRides += 1
                // Simulate next offer after 5s
                return .run { send in
                    try await Task.sleep(for: .seconds(5))
                    await send(.offerAppeared)
                }

            case .earningsTapped:
                state.path.append(.earnings(EarningsFeature.State(
                    todayTenge: state.earnings.todayTenge,
                    todayRides: state.earnings.todayRides,
                    weekTenge: state.earnings.weekTenge
                )))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
