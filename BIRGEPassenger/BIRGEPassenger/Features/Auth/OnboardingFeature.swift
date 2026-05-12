import BIRGECore
import ComposableArchitecture
import Foundation

// MARK: - PassengerSetupFeature

@Reducer
struct PassengerSetupFeature {
    @ObservableState
    struct State: Equatable {
        enum Step: Equatable, Sendable {
            case profileBasics
            case trustConsent
            case productIntro
            case firstRouteEntry
        }

        enum RouteStep: Equatable, Sendable {
            case originAddress
            case pickupNode
            case destinationAddress
            case dropoffNode
            case schedule
            case review
        }

        var phoneNumber: String?
        var step: Step
        var routeStep: RouteStep
        var fullName: String
        var city: String
        var email: String
        var notificationsConsent: Bool
        var locationConsent: Bool
        var routePrivacyConsent: Bool
        var productIntroCompleted: Bool
        var routeDraft: MockRouteDraft?
        var originAddressQuery: String
        var originAddressResults: [MockAddressSearchResult]
        var selectedOriginAddress: MockAddressSearchResult?
        var suggestedPickupNodes: [MockCommuteNode]
        var selectedPickupNodeID: MockCommuteNode.ID?
        var destinationAddressQuery: String
        var destinationAddressResults: [MockAddressSearchResult]
        var selectedDestinationAddress: MockAddressSearchResult?
        var suggestedDropoffNodes: [MockCommuteNode]
        var selectedDropoffNodeID: MockCommuteNode.ID?
        var availableWeekdays: [String]
        var selectedWeekdays: Set<String>
        var departureTime: String
        var flexibilityMinutes: Int
        var isSaving: Bool
        var isLoadingRouteData: Bool
        var errorMessage: String?

        init(
            phoneNumber: String? = nil,
            initialStep: Step = .profileBasics,
            routeStep: RouteStep = .originAddress,
            fullName: String = "",
            city: String = "",
            email: String = "",
            notificationsConsent: Bool = false,
            locationConsent: Bool = false,
            routePrivacyConsent: Bool = false,
            productIntroCompleted: Bool = false,
            routeDraft: MockRouteDraft? = nil,
            originAddressQuery: String = "",
            originAddressResults: [MockAddressSearchResult] = [],
            selectedOriginAddress: MockAddressSearchResult? = nil,
            suggestedPickupNodes: [MockCommuteNode] = [],
            selectedPickupNodeID: MockCommuteNode.ID? = nil,
            destinationAddressQuery: String = "",
            destinationAddressResults: [MockAddressSearchResult] = [],
            selectedDestinationAddress: MockAddressSearchResult? = nil,
            suggestedDropoffNodes: [MockCommuteNode] = [],
            selectedDropoffNodeID: MockCommuteNode.ID? = nil,
            availableWeekdays: [String] = BIRGEProductFixtures.Passenger.morningSchedule.weekdays,
            selectedWeekdays: Set<String> = [],
            departureTime: String = "",
            flexibilityMinutes: Int = 15,
            isSaving: Bool = false,
            isLoadingRouteData: Bool = false,
            errorMessage: String? = nil
        ) {
            self.phoneNumber = phoneNumber
            self.step = initialStep
            self.routeStep = routeStep
            self.fullName = fullName
            self.city = city
            self.email = email
            self.notificationsConsent = notificationsConsent
            self.locationConsent = locationConsent
            self.routePrivacyConsent = routePrivacyConsent
            self.productIntroCompleted = productIntroCompleted
            self.routeDraft = routeDraft
            self.originAddressQuery = originAddressQuery
            self.originAddressResults = originAddressResults
            self.selectedOriginAddress = selectedOriginAddress
            self.suggestedPickupNodes = suggestedPickupNodes
            self.selectedPickupNodeID = selectedPickupNodeID
            self.destinationAddressQuery = destinationAddressQuery
            self.destinationAddressResults = destinationAddressResults
            self.selectedDestinationAddress = selectedDestinationAddress
            self.suggestedDropoffNodes = suggestedDropoffNodes
            self.selectedDropoffNodeID = selectedDropoffNodeID
            self.availableWeekdays = availableWeekdays
            self.selectedWeekdays = selectedWeekdays
            self.departureTime = departureTime
            self.flexibilityMinutes = flexibilityMinutes
            self.isSaving = isSaving
            self.isLoadingRouteData = isLoadingRouteData
            self.errorMessage = errorMessage
        }

        init(phoneNumber: String?, passengerSetupStep: PassengerSetupStep?) {
            self.init(
                phoneNumber: phoneNumber,
                initialStep: Self.step(for: passengerSetupStep)
            )
        }

        var canGoBack: Bool {
            step != .profileBasics
        }

        var canContinue: Bool {
            switch step {
            case .profileBasics:
                return !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !isSaving
            case .trustConsent:
                return notificationsConsent && locationConsent && routePrivacyConsent && !isSaving
            case .productIntro:
                return !isSaving
            case .firstRouteEntry:
                return canContinueRoute
            }
        }

        var canContinueRoute: Bool {
            guard !isSaving && !isLoadingRouteData else { return false }

            switch routeStep {
            case .originAddress:
                return selectedOriginAddress != nil
            case .pickupNode:
                return selectedPickupNodeID != nil
            case .destinationAddress:
                return selectedDestinationAddress != nil
            case .dropoffNode:
                return selectedDropoffNodeID != nil
            case .schedule:
                return !selectedWeekdays.isEmpty
                    && !departureTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .review:
                return routeDraftForReview != nil
            }
        }

        var stepTitle: String {
            switch step {
            case .profileBasics:
                return "Profile basics"
            case .trustConsent:
                return "Trust and consent"
            case .productIntro:
                return "Product intro"
            case .firstRouteEntry:
                switch routeStep {
                case .originAddress:
                    return "Origin address"
                case .pickupNode:
                    return "Pickup node"
                case .destinationAddress:
                    return "Destination address"
                case .dropoffNode:
                    return "Dropoff node"
                case .schedule:
                    return "Route schedule"
                case .review:
                    return "Route review"
                }
            }
        }

        var routeDraftForReview: MockRouteDraft? {
            guard let selectedOriginAddress,
                  let selectedDestinationAddress,
                  selectedPickupNodeID != nil,
                  selectedDropoffNodeID != nil,
                  !selectedWeekdays.isEmpty,
                  !departureTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            return MockRouteDraft(
                id: routeDraft?.id ?? UUID(),
                displayName: "\(selectedOriginAddress.title) -> \(selectedDestinationAddress.title)",
                originAddress: selectedOriginAddress.fullAddress,
                destinationAddress: selectedDestinationAddress.fullAddress,
                suggestedPickupNodes: suggestedPickupNodes,
                suggestedDropoffNodes: suggestedDropoffNodes,
                selectedPickupNodeID: selectedPickupNodeID,
                selectedDropoffNodeID: selectedDropoffNodeID,
                schedule: MockRouteSchedule(
                    weekdays: selectedWeekdays.sorted(),
                    departureWindowStart: departureTime,
                    departureWindowEnd: departureWindowEnd
                )
            )
        }

        var departureWindowEnd: String {
            Self.time(departureTime, addingMinutes: flexibilityMinutes)
        }

        var progressStepIndex: Int {
            Self.progressStepIndex(step: step, routeStep: routeStep)
        }

        var progressStepCount: Int {
            Self.progressStepCount
        }

        static func step(for passengerSetupStep: PassengerSetupStep?) -> Step {
            switch passengerSetupStep {
            case nil, .profileBasics:
                return .profileBasics
            case .trustConsent:
                return .trustConsent
            case .productIntro:
                return .productIntro
            case .routeOrigin, .routeDestination, .routeSchedule, .routeReview, .monthlyPlan:
                return .firstRouteEntry
            }
        }

        static let progressStepCount = 9

        static func progressStepIndex(step: Step, routeStep: RouteStep) -> Int {
            switch step {
            case .profileBasics:
                return 1
            case .trustConsent:
                return 2
            case .productIntro:
                return 3
            case .firstRouteEntry:
                switch routeStep {
                case .originAddress:
                    return 4
                case .pickupNode:
                    return 5
                case .destinationAddress:
                    return 6
                case .dropoffNode:
                    return 7
                case .schedule:
                    return 8
                case .review:
                    return 9
                }
            }
        }

        private static func time(_ time: String, addingMinutes minutesToAdd: Int) -> String {
            let parts = time.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return time }

            let totalMinutes = max(0, min((parts[0] * 60) + parts[1] + minutesToAdd, (24 * 60) - 1))
            return String(format: "%02d:%02d", totalMinutes / 60, totalMinutes % 60)
        }
    }

    @CasePathable
    enum Action: Equatable, Sendable {
        case fullNameChanged(String)
        case cityChanged(String)
        case emailChanged(String)
        case notificationsConsentToggled
        case locationConsentToggled
        case routePrivacyConsentToggled
        case originQueryChanged(String)
        case originAddressResultsLoaded([MockAddressSearchResult])
        case originAddressSelected(MockAddressSearchResult)
        case pickupNodesLoaded([MockCommuteNode])
        case pickupNodeSelected(MockCommuteNode.ID)
        case destinationQueryChanged(String)
        case destinationAddressResultsLoaded([MockAddressSearchResult])
        case destinationAddressSelected(MockAddressSearchResult)
        case dropoffNodesLoaded([MockCommuteNode])
        case dropoffNodeSelected(MockCommuteNode.ID)
        case weekdayToggled(String)
        case departureTimeChanged(String)
        case departureHourChanged(Int)
        case departureMinuteChanged(Int)
        case flexibilityMinutesChanged(Int)
        case continueTapped
        case backTapped
        case profileSaveSucceeded
        case consentSaveSucceeded
        case productIntroSaveSucceeded(MockRouteDraft)
        case routeDraftSaveSucceeded(MockRouteDraft)
        case saveFailed(String)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable, Sendable {
            case readyForFirstRouteSetup(MockRouteDraft?)
            case routeDraftReadyForSubscription(MockRouteDraft)
        }
    }

    @Dependency(\.passengerProfileClient) var passengerProfileClient
    @Dependency(\.passengerRouteClient) var passengerRouteClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .fullNameChanged(fullName):
                state.fullName = fullName
                state.errorMessage = nil
                return .none

            case let .cityChanged(city):
                state.city = city
                state.errorMessage = nil
                return .none

            case let .emailChanged(email):
                state.email = email
                state.errorMessage = nil
                return .none

            case .notificationsConsentToggled:
                state.notificationsConsent.toggle()
                state.errorMessage = nil
                return .none

            case .locationConsentToggled:
                state.locationConsent.toggle()
                state.errorMessage = nil
                return .none

            case .routePrivacyConsentToggled:
                state.routePrivacyConsent.toggle()
                state.errorMessage = nil
                return .none

            case let .originQueryChanged(query):
                state.originAddressQuery = query
                state.selectedOriginAddress = nil
                state.suggestedPickupNodes = []
                state.selectedPickupNodeID = nil
                state.errorMessage = nil
                state.isLoadingRouteData = true
                return .run { send in
                    let results = await passengerRouteClient.searchAddresses(query)
                    await send(.originAddressResultsLoaded(results))
                }

            case let .originAddressResultsLoaded(results):
                state.isLoadingRouteData = false
                state.originAddressResults = results
                return .none

            case let .originAddressSelected(result):
                state.selectedOriginAddress = result
                state.originAddressQuery = result.fullAddress
                state.originAddressResults = []
                state.suggestedPickupNodes = []
                state.selectedPickupNodeID = nil
                state.errorMessage = nil
                state.isLoadingRouteData = true
                return .run { send in
                    let nodes = await passengerRouteClient.suggestedPickupNodes(result.fullAddress)
                    await send(.pickupNodesLoaded(nodes))
                }

            case let .pickupNodesLoaded(nodes):
                state.isLoadingRouteData = false
                state.suggestedPickupNodes = nodes
                return .none

            case let .pickupNodeSelected(id):
                state.selectedPickupNodeID = id
                state.errorMessage = nil
                return .none

            case let .destinationQueryChanged(query):
                state.destinationAddressQuery = query
                state.selectedDestinationAddress = nil
                state.suggestedDropoffNodes = []
                state.selectedDropoffNodeID = nil
                state.errorMessage = nil
                state.isLoadingRouteData = true
                return .run { send in
                    let results = await passengerRouteClient.searchAddresses(query)
                    await send(.destinationAddressResultsLoaded(results))
                }

            case let .destinationAddressResultsLoaded(results):
                state.isLoadingRouteData = false
                state.destinationAddressResults = results
                return .none

            case let .destinationAddressSelected(result):
                state.selectedDestinationAddress = result
                state.destinationAddressQuery = result.fullAddress
                state.destinationAddressResults = []
                state.suggestedDropoffNodes = []
                state.selectedDropoffNodeID = nil
                state.errorMessage = nil
                state.isLoadingRouteData = true
                return .run { send in
                    let nodes = await passengerRouteClient.suggestedDropoffNodes(result.fullAddress)
                    await send(.dropoffNodesLoaded(nodes))
                }

            case let .dropoffNodesLoaded(nodes):
                state.isLoadingRouteData = false
                state.suggestedDropoffNodes = nodes
                return .none

            case let .dropoffNodeSelected(id):
                state.selectedDropoffNodeID = id
                state.errorMessage = nil
                return .none

            case let .weekdayToggled(weekday):
                if state.selectedWeekdays.contains(weekday) {
                    state.selectedWeekdays.remove(weekday)
                } else {
                    state.selectedWeekdays.insert(weekday)
                }
                state.errorMessage = nil
                return .none

            case let .departureTimeChanged(time):
                state.departureTime = time
                state.errorMessage = nil
                return .none

            case let .departureHourChanged(hour):
                let minute = Self.minuteComponent(from: state.departureTime)
                state.departureTime = Self.timeString(hour: hour, minute: minute)
                state.errorMessage = nil
                return .none

            case let .departureMinuteChanged(minute):
                let hour = Self.hourComponent(from: state.departureTime)
                state.departureTime = Self.timeString(hour: hour, minute: minute)
                state.errorMessage = nil
                return .none

            case let .flexibilityMinutesChanged(minutes):
                state.flexibilityMinutes = max(0, minutes)
                state.errorMessage = nil
                return .none

            case .continueTapped:
                guard state.canContinue else { return .none }

                switch state.step {
                case .profileBasics:
                    state.isSaving = true
                    state.errorMessage = nil
                    let phoneNumber = state.phoneNumber
                    let draft = MockPassengerProfileBasicsDraft(
                        fullName: state.fullName,
                        city: state.city,
                        email: state.email
                    )
                    return .run { send in
                        if let phoneNumber {
                            try await passengerProfileClient.saveProfileBasics(phoneNumber, draft)
                            try await passengerProfileClient.updateOnboardingProgress(phoneNumber, .trustConsent)
                        }
                        await send(.profileSaveSucceeded)
                    } catch: { error, send in
                        await send(.saveFailed(error.localizedDescription))
                    }

                case .trustConsent:
                    state.isSaving = true
                    state.errorMessage = nil
                    let phoneNumber = state.phoneNumber
                    let draft = MockPassengerConsentDraft(
                        notificationsConsent: state.notificationsConsent,
                        locationConsent: state.locationConsent,
                        routePrivacyConsent: state.routePrivacyConsent
                    )
                    return .run { send in
                        if let phoneNumber {
                            try await passengerProfileClient.saveTrustConsent(phoneNumber, draft)
                            try await passengerProfileClient.updateOnboardingProgress(phoneNumber, .productIntro)
                        }
                        await send(.consentSaveSucceeded)
                    } catch: { error, send in
                        await send(.saveFailed(error.localizedDescription))
                    }

                case .productIntro:
                    state.isSaving = true
                    state.errorMessage = nil
                    let phoneNumber = state.phoneNumber
                    return .run { send in
                        if let phoneNumber {
                            try await passengerProfileClient.updateOnboardingProgress(phoneNumber, .routeOrigin)
                        }
                        let routeDraft = await passengerRouteClient.draftRoute()
                        await send(.productIntroSaveSucceeded(routeDraft))
                    } catch: { error, send in
                        await send(.saveFailed(error.localizedDescription))
                    }

                case .firstRouteEntry:
                    return continueRouteSetup(&state)
                }

            case .backTapped:
                if state.step == .firstRouteEntry, let previousRouteStep = previousRouteStep(before: state.routeStep) {
                    state.routeStep = previousRouteStep
                } else {
                    state.step = previousStep(before: state.step) ?? state.step
                }
                state.errorMessage = nil
                return .none

            case .profileSaveSucceeded:
                state.isSaving = false
                state.step = .trustConsent
                return .none

            case .consentSaveSucceeded:
                state.isSaving = false
                state.step = .productIntro
                return .none

            case let .productIntroSaveSucceeded(routeDraft):
                state.isSaving = false
                state.productIntroCompleted = true
                state.routeDraft = routeDraft
                state.step = .firstRouteEntry
                return .none

            case let .routeDraftSaveSucceeded(routeDraft):
                state.isSaving = false
                state.routeDraft = routeDraft
                return .send(.delegate(.routeDraftReadyForSubscription(routeDraft)))

            case let .saveFailed(message):
                state.isSaving = false
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func previousStep(before step: State.Step) -> State.Step? {
        switch step {
        case .profileBasics:
            return nil
        case .trustConsent:
            return .profileBasics
        case .productIntro:
            return .trustConsent
        case .firstRouteEntry:
            return .productIntro
        }
    }

    private func previousRouteStep(before step: State.RouteStep) -> State.RouteStep? {
        switch step {
        case .originAddress:
            return nil
        case .pickupNode:
            return .originAddress
        case .destinationAddress:
            return .pickupNode
        case .dropoffNode:
            return .destinationAddress
        case .schedule:
            return .dropoffNode
        case .review:
            return .schedule
        }
    }

    private func continueRouteSetup(_ state: inout State) -> Effect<Action> {
        switch state.routeStep {
        case .originAddress:
            state.routeStep = .pickupNode
            return .none

        case .pickupNode:
            state.routeStep = .destinationAddress
            return .none

        case .destinationAddress:
            state.routeStep = .dropoffNode
            return .none

        case .dropoffNode:
            state.routeStep = .schedule
            return .none

        case .schedule:
            state.routeStep = .review
            return .none

        case .review:
            guard let draft = state.routeDraftForReview else { return .none }
            state.isSaving = true
            state.errorMessage = nil
            return .run { send in
                let savedDraft = try await passengerRouteClient.saveRouteDraft(draft)
                await send(.routeDraftSaveSucceeded(savedDraft))
            } catch: { error, send in
                await send(.saveFailed(error.localizedDescription))
            }
        }
    }

    private static func hourComponent(from time: String) -> Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        return parts.first.map { max(0, min(23, $0)) } ?? 7
    }

    private static func minuteComponent(from time: String) -> Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count > 1 else { return 45 }
        return max(0, min(59, parts[1]))
    }

    private static func timeString(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", max(0, min(23, hour)), max(0, min(59, minute)))
    }
}

typealias OnboardingFeature = PassengerSetupFeature
