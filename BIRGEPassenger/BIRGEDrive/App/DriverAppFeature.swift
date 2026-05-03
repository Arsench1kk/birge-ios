//
//  DriverAppFeature.swift
//  BIRGEDrive
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
        var pickup: String
        var destination: String
        var fare: Int
        var distanceKm: Double
        var etaMinutes: Int
        var status: RideStatus

        enum RideStatus: Equatable, Sendable {
            case pickingUp
            case passengerWait
            case inProgress
        }
    }

    struct CompletedRideSummary: Equatable, Sendable {
        var fare: Int
        var durationMinutes: Int
        var distanceKm: Double
        var passengers: Int
        var todayTenge: Int
        var todayRides: Int
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
        var isRegistrationComplete = false
        var registration = DriverRegistrationFeature.State()
        var isOnline: Bool = false
        var currentOffer: RideOffer? = nil
        var activeRide: DriverActiveRide? = nil
        var completedRideSummary: CompletedRideSummary? = nil
        var earnings: DriverEarnings = .mock
        var path = StackState<Path.State>()

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.isRegistrationComplete == rhs.isRegistrationComplete &&
            lhs.registration == rhs.registration &&
            lhs.isOnline == rhs.isOnline &&
            lhs.currentOffer == rhs.currentOffer &&
            lhs.activeRide == rhs.activeRide &&
            lhs.completedRideSummary == rhs.completedRideSummary &&
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
        case dismissCompletedRide
        case findNextRide
        case earningsTapped
        case path(StackActionOf<Path>)
        case registration(DriverRegistrationFeature.Action)
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.registration, action: \.registration) {
            DriverRegistrationFeature()
        }
        Reduce { state, action in
            switch action {
            case .registration(.delegate(.completed)):
                state.isRegistrationComplete = true
                return .none

            case .toggleOnline:
                state.isOnline.toggle()
                if !state.isOnline {
                    // Going offline — clear active state
                    state.currentOffer = nil
                    state.activeRide = nil
                    state.completedRideSummary = nil
                    return .none
                }
                // Going online — simulate offer arriving after 4s
                return .run { send in
                    try await Task.sleep(for: .seconds(4))
                    await send(.offerAppeared)
                }

            case .offerAppeared:
                guard state.isOnline, state.activeRide == nil, state.completedRideSummary == nil else { return .none }
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
                    pickup: "Алатау, ул. Момышулы 15",
                    destination: "Есентай Молл",
                    fare: 1850,
                    distanceKm: 7.2,
                    etaMinutes: 6,
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
                state.activeRide?.etaMinutes = 35
                return .none

            case .startRide:
                state.activeRide?.status = .inProgress
                state.activeRide?.etaMinutes = 28
                return .none

            case .completeRide:
                let completedRide = state.activeRide
                state.activeRide = nil
                let fare = completedRide?.fare ?? 1850
                let distance = completedRide?.distanceKm ?? 7.2
                state.earnings.todayTenge += fare
                state.earnings.todayRides += 1
                state.completedRideSummary = CompletedRideSummary(
                    fare: fare,
                    durationMinutes: 18,
                    distanceKm: distance,
                    passengers: 4,
                    todayTenge: state.earnings.todayTenge,
                    todayRides: state.earnings.todayRides
                )
                return .none

            case .dismissCompletedRide:
                state.completedRideSummary = nil
                return .none

            case .findNextRide:
                state.completedRideSummary = nil
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.offerAppeared)
                }

            case .earningsTapped:
                state.path.append(.earnings(EarningsFeature.State(
                    todayTenge: state.earnings.todayTenge,
                    todayRides: state.earnings.todayRides,
                    weekTenge: state.earnings.weekTenge
                )))
                return .none

            case .path, .registration:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
