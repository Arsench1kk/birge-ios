//
//  DriverAppFeature.swift
//  BIRGEDrive
//

import ComposableArchitecture
import BIRGECore
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
        var rideID: String
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

    struct DriverDashboardCorridor: Equatable, Identifiable, Sendable {
        var id: UUID
        var name: String
        var originName: String
        var destinationName: String
        var departure: String
        var seatsTotal: Int
        var passengerInitials: [String]
        var estimatedEarnings: Int
        var status: String

        nonisolated init(dto: DriverTodayCorridorDTO) {
            self.id = dto.id
            self.name = dto.name
            self.originName = dto.originName
            self.destinationName = dto.destinationName
            self.departure = dto.departure
            self.seatsTotal = dto.seatsTotal
            self.passengerInitials = dto.passengerInitials
            self.estimatedEarnings = dto.estimatedEarnings
            self.status = dto.status
        }
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
        var driverName: String = "Водитель"
        var vehicleTitle: String = "Автомобиль не указан"
        var todayCorridors: [DriverDashboardCorridor] = []
        var isLoadingDriverProfile = false
        var isLoadingTodayCorridors = false
        var driverProfileError: String?
        var todayCorridorsError: String?
        var path = StackState<Path.State>()

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.isRegistrationComplete == rhs.isRegistrationComplete &&
            lhs.registration == rhs.registration &&
            lhs.isOnline == rhs.isOnline &&
            lhs.currentOffer == rhs.currentOffer &&
            lhs.activeRide == rhs.activeRide &&
            lhs.completedRideSummary == rhs.completedRideSummary &&
            lhs.earnings == rhs.earnings &&
            lhs.driverName == rhs.driverName &&
            lhs.vehicleTitle == rhs.vehicleTitle &&
            lhs.todayCorridors == rhs.todayCorridors &&
            lhs.isLoadingDriverProfile == rhs.isLoadingDriverProfile &&
            lhs.isLoadingTodayCorridors == rhs.isLoadingTodayCorridors &&
            lhs.driverProfileError == rhs.driverProfileError &&
            lhs.todayCorridorsError == rhs.todayCorridorsError
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
        case task
        case driverProfileResponse(Result<DriverProfileDTO, DriverDashboardError>)
        case todayCorridorsResponse(Result<DriverTodayCorridorsResponse, DriverDashboardError>)
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

    @Dependency(\.locationClient) var locationClient
    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Scope(state: \.registration, action: \.registration) {
            DriverRegistrationFeature()
        }
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoadingDriverProfile = true
                state.isLoadingTodayCorridors = true
                state.driverProfileError = nil
                state.todayCorridorsError = nil
                return .merge(
                    .run { send in
                        do {
                            await send(.driverProfileResponse(.success(try await apiClient.fetchDriverProfile())))
                        } catch {
                            await send(.driverProfileResponse(.failure(DriverDashboardError(error))))
                        }
                    },
                    .run { send in
                        do {
                            await send(.todayCorridorsResponse(.success(try await apiClient.fetchDriverTodayCorridors())))
                        } catch {
                            await send(.todayCorridorsResponse(.failure(DriverDashboardError(error))))
                        }
                    }
                )

            case .driverProfileResponse(.success(let profile)):
                state.isLoadingDriverProfile = false
                state.driverProfileError = nil
                state.apply(driverProfile: profile)
                return .none

            case .driverProfileResponse(.failure(let error)):
                state.isLoadingDriverProfile = false
                state.driverProfileError = error.message
                return .none

            case .todayCorridorsResponse(.success(let response)):
                state.isLoadingTodayCorridors = false
                state.todayCorridorsError = nil
                state.todayCorridors = response.corridors.map(DriverDashboardCorridor.init)
                if response.todayEarningsEstimate > 0 {
                    state.earnings.todayTenge = response.todayEarningsEstimate
                }
                return .none

            case .todayCorridorsResponse(.failure(let error)):
                state.isLoadingTodayCorridors = false
                state.todayCorridorsError = error.message
                return .none

            case .registration(.delegate(.completed(let profile))):
                state.isRegistrationComplete = true
                state.apply(driverProfile: profile)
                state.isLoadingTodayCorridors = true
                return .run { send in
                    do {
                        await send(.todayCorridorsResponse(.success(try await apiClient.fetchDriverTodayCorridors())))
                    } catch {
                        await send(.todayCorridorsResponse(.failure(DriverDashboardError(error))))
                    }
                }

            case .toggleOnline:
                state.isOnline.toggle()
                if !state.isOnline {
                    // Going offline — clear active state
                    let rideID = state.activeRide?.rideID
                    state.currentOffer = nil
                    state.activeRide = nil
                    state.completedRideSummary = nil
                    return .merge(
                        .cancel(id: DriverLocationCancelID.tracking),
                        stopAndSyncDriverLocation(rideID: rideID)
                    )
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
                let rideID = UUID().uuidString
                state.activeRide = DriverActiveRide(
                    rideID: rideID,
                    passengerName: "Арсен А.",
                    pickup: "Алатау, ул. Момышулы 15",
                    destination: "Есентай Молл",
                    fare: 1850,
                    distanceKm: 7.2,
                    etaMinutes: 6,
                    status: .pickingUp
                )
                return startDriverLocationTracking(rideID: rideID)

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
                return .merge(
                    .cancel(id: DriverLocationCancelID.tracking),
                    stopAndSyncDriverLocation(rideID: completedRide?.rideID)
                )

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

    private enum DriverLocationCancelID {
        static let tracking = "DriverAppFeature.locationTracking"
    }

    private func startDriverLocationTracking(rideID: String) -> Effect<Action> {
        .run { _ in
            let stream = await locationClient.startTracking(rideID)
            for await _ in stream {
                // LocationClient writes every update to GRDB. The dashboard
                // does not need per-point reducer state yet.
            }
        }
        .cancellable(id: DriverLocationCancelID.tracking)
    }

    private func stopAndSyncDriverLocation(rideID: String?) -> Effect<Action> {
        .run { _ in
            await locationClient.stopTracking()
            if let rideID {
                try? await locationClient.syncPendingLocations(rideID)
            }
        }
    }
}

struct DriverDashboardError: Error, Equatable, Sendable {
    let message: String

    init(_ error: any Error) {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.isEmpty {
            self.message = description
        } else {
            self.message = "Не удалось загрузить данные водителя"
        }
    }
}

private extension DriverAppFeature.State {
    mutating func apply(driverProfile profile: DriverProfileDTO) {
        driverName = profile.name
            ?? [profile.firstName, profile.lastName]
                .compactMap { $0 }
                .joined(separator: " ")
        if driverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            driverName = "Водитель"
        }

        let vehicleParts = [profile.vehicleMake, profile.vehicleModel, profile.vehicleYear]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        vehicleTitle = vehicleParts.isEmpty ? "Автомобиль не указан" : vehicleParts.joined(separator: " ")
        if let plate = profile.licensePlate, !plate.isEmpty {
            vehicleTitle += " • \(plate)"
        }

        let hasCoreRegistration = profile.firstName?.isEmpty == false && profile.vehicleModel?.isEmpty == false
        isRegistrationComplete = profile.kycStatus != "draft" || hasCoreRegistration
    }
}
