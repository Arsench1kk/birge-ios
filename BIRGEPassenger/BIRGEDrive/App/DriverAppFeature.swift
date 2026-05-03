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
        var rideID: String
        var passengerName: String
        var pickup: String
        var destination: String
        var fare: Int
        var distanceKm: Double
        var etaMinutes: Int

        nonisolated init(dto: DriverRideOfferDTO) {
            self.rideID = dto.rideID.uuidString
            self.passengerName = dto.passengerName
            self.pickup = dto.pickup
            self.destination = dto.destination
            self.fare = dto.fare
            self.distanceKm = dto.distanceKm
            self.etaMinutes = dto.etaMinutes
        }

        static let demo = RideOffer(dto: .demo())
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
        var isAuthenticated = false
        var auth = DriverAuthFeature.State()
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
            lhs.isAuthenticated == rhs.isAuthenticated &&
            lhs.auth == rhs.auth &&
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
        case driverOffersResponse(Result<DriverRideOffersResponse, DriverDashboardError>)
        case acceptRideResponse(Result<DriverRideOfferDTO, DriverDashboardError>)
        case driverCommandResponse(Result<DriverRideOfferDTO, DriverDashboardError>)
        case auth(DriverAuthFeature.Action)
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
        Scope(state: \.auth, action: \.auth) {
            DriverAuthFeature()
        }
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
                state.isAuthenticated = true
                state.driverProfileError = nil
                state.apply(driverProfile: profile)
                return .none

            case .driverProfileResponse(.failure(let error)):
                state.isLoadingDriverProfile = false
                if error.isMissingAccessToken {
                    state.isAuthenticated = false
                }
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

            case .driverOffersResponse(.success(let response)):
                guard state.isOnline, state.activeRide == nil, state.completedRideSummary == nil else { return .none }
                state.currentOffer = response.offers.first.map(RideOffer.init)
                if state.currentOffer == nil {
                    return pollDriverOffers(after: .seconds(6))
                }
                return .none

            case .driverOffersResponse(.failure(let error)):
                guard state.isOnline, state.activeRide == nil, state.completedRideSummary == nil else { return .none }
                state.todayCorridorsError = error.message
                return .none

            case .acceptRideResponse(.success(let offer)):
                state.currentOffer = nil
                state.activeRide = DriverActiveRide(offer: offer, status: .pickingUp)
                return startDriverLocationTracking(rideID: offer.rideID.uuidString)

            case .acceptRideResponse(.failure(let error)):
                state.todayCorridorsError = error.message
                state.currentOffer = nil
                return pollDriverOffers(after: .seconds(3))

            case .driverCommandResponse(.success(let offer)):
                state.activeRide?.etaMinutes = offer.etaMinutes
                return .none

            case .driverCommandResponse(.failure):
                return .none

            case .auth(.delegate(.authenticated)):
                state.isAuthenticated = true
                return .send(.task)

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
                return pollDriverOffers(after: .seconds(1))

            case .offerAppeared:
                guard state.isOnline, state.activeRide == nil, state.completedRideSummary == nil else { return .none }
                return fetchDriverOffers()

            case .acceptOffer:
                guard let offer = state.currentOffer else { return .none }
                return .run { send in
                    do {
                        await send(.acceptRideResponse(.success(try await apiClient.acceptDriverRide(offer.rideID))))
                    } catch {
                        await send(.acceptRideResponse(.failure(DriverDashboardError(error))))
                    }
                }

            case .declineOffer:
                state.currentOffer = nil
                // Wait and show next offer
                return .run { send in
                    try await Task.sleep(for: .seconds(6))
                    await send(.offerAppeared)
                }

            case .arrivedAtPickup:
                let rideID = state.activeRide?.rideID
                state.activeRide?.status = .passengerWait
                state.activeRide?.etaMinutes = 35
                return sendDriverCommand(rideID: rideID, command: .arrived)

            case .startRide:
                let rideID = state.activeRide?.rideID
                state.activeRide?.status = .inProgress
                state.activeRide?.etaMinutes = 28
                return sendDriverCommand(rideID: rideID, command: .start)

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
                    sendDriverCommand(rideID: completedRide?.rideID, command: .complete),
                    .cancel(id: DriverLocationCancelID.tracking),
                    stopAndSyncDriverLocation(rideID: completedRide?.rideID)
                )

            case .dismissCompletedRide:
                state.completedRideSummary = nil
                return .none

            case .findNextRide:
                state.completedRideSummary = nil
                return pollDriverOffers(after: .seconds(2))

            case .earningsTapped:
                state.path.append(.earnings(EarningsFeature.State(
                    todayTenge: state.earnings.todayTenge,
                    todayRides: state.earnings.todayRides,
                    weekTenge: state.earnings.weekTenge
                )))
                return .none

            case .path, .registration, .auth:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    private enum DriverLocationCancelID {
        static let tracking = "DriverAppFeature.locationTracking"
    }

    private enum DriverCommand {
        case arrived
        case start
        case complete
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

    private func pollDriverOffers(after delay: Duration) -> Effect<Action> {
        .run { send in
            try await Task.sleep(for: delay)
            await send(.offerAppeared)
        }
    }

    private func fetchDriverOffers() -> Effect<Action> {
        .run { send in
            do {
                await send(.driverOffersResponse(.success(try await apiClient.fetchDriverRideOffers())))
            } catch {
                await send(.driverOffersResponse(.failure(DriverDashboardError(error))))
            }
        }
    }

    private func sendDriverCommand(rideID: String?, command: DriverCommand) -> Effect<Action> {
        guard let rideID else { return .none }
        return .run { send in
            do {
                let offer: DriverRideOfferDTO
                switch command {
                case .arrived:
                    offer = try await apiClient.markDriverArrived(rideID)
                case .start:
                    offer = try await apiClient.startDriverRide(rideID)
                case .complete:
                    offer = try await apiClient.completeDriverRide(rideID)
                }
                await send(.driverCommandResponse(.success(offer)))
            } catch {
                await send(.driverCommandResponse(.failure(DriverDashboardError(error))))
            }
        }
    }
}

@Reducer
struct DriverAuthFeature {
    @ObservableState
    struct State: Equatable {
        var mode: Mode = .login
        var email = "driver@birge.kz"
        var password = "driver123"
        var phone = "+77770000001"
        var name = "Асан Б."
        var isLoading = false
        var errorMessage: String?

        enum Mode: Equatable, Sendable {
            case login
            case register
        }

        var title: String {
            mode == .login ? "Вход для водителя" : "Регистрация водителя"
        }

        var primaryTitle: String {
            mode == .login ? "Войти" : "Создать аккаунт"
        }
    }

    enum Action: Equatable, Sendable {
        case modeToggled
        case emailChanged(String)
        case passwordChanged(String)
        case phoneChanged(String)
        case nameChanged(String)
        case submitTapped
        case authResponse(Result<APIAuthResponse, DriverAuthError>)
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            case authenticated
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .modeToggled:
                state.mode = state.mode == .login ? .register : .login
                state.errorMessage = nil
                return .none

            case .emailChanged(let value):
                state.email = value
                state.errorMessage = nil
                return .none

            case .passwordChanged(let value):
                state.password = value
                state.errorMessage = nil
                return .none

            case .phoneChanged(let value):
                state.phone = value
                state.errorMessage = nil
                return .none

            case .nameChanged(let value):
                state.name = value
                state.errorMessage = nil
                return .none

            case .submitTapped:
                guard !state.email.isEmpty, !state.password.isEmpty else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let mode = state.mode
                let email = state.email
                let password = state.password
                let phone = state.phone
                let name = state.name
                return .run { send in
                    do {
                        let response: APIAuthResponse
                        switch mode {
                        case .login:
                            response = try await apiClient.login(email, password)
                        case .register:
                            response = try await apiClient.registerDriver(email, password, phone, name)
                        }
                        await send(.authResponse(.success(response)))
                    } catch {
                        await send(.authResponse(.failure(DriverAuthError(error))))
                    }
                }

            case .authResponse(.success(let response)):
                state.isLoading = false
                guard response.role == "driver" else {
                    state.errorMessage = "Этот аккаунт не является водительским"
                    return .none
                }
                return .send(.delegate(.authenticated))

            case .authResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

struct DriverAuthError: Error, Equatable, Sendable {
    let message: String

    init(_ error: any Error) {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.isEmpty {
            self.message = description
        } else {
            self.message = "Не удалось войти"
        }
    }
}

struct DriverDashboardError: Error, Equatable, Sendable {
    let message: String
    let isMissingAccessToken: Bool

    init(_ error: any Error) {
        if let apiError = error as? BIRGEAPIError {
            self.isMissingAccessToken = apiError.errorCode == "MISSING_ACCESS_TOKEN"
        } else {
            self.isMissingAccessToken = false
        }

        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.isEmpty {
            self.message = description
        } else {
            self.message = "Не удалось загрузить данные водителя"
        }
    }
}

private extension DriverAppFeature.DriverActiveRide {
    init(offer: DriverRideOfferDTO, status: RideStatus) {
        self.rideID = offer.rideID.uuidString
        self.passengerName = offer.passengerName
        self.pickup = offer.pickup
        self.destination = offer.destination
        self.fare = offer.fare
        self.distanceKm = offer.distanceKm
        self.etaMinutes = offer.etaMinutes
        self.status = status
    }

    init(offer: DriverAppFeature.RideOffer, status: RideStatus) {
        self.rideID = offer.rideID
        self.passengerName = offer.passengerName
        self.pickup = offer.pickup
        self.destination = offer.destination
        self.fare = offer.fare
        self.distanceKm = offer.distanceKm
        self.etaMinutes = offer.etaMinutes
        self.status = status
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
        isRegistrationComplete = hasCoreRegistration
    }
}
