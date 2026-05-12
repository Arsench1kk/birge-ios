import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class PassengerSetupFeatureTests: XCTestCase {
    func testUnknownPhoneStartsAtProfileBasics() {
        let state = OnboardingFeature.State(
            phoneNumber: BIRGEProductFixtures.Phones.unknownPassenger,
            passengerSetupStep: .profileBasics
        )

        XCTAssertEqual(state.step, .profileBasics)
        XCTAssertEqual(state.phoneNumber, BIRGEProductFixtures.Phones.unknownPassenger)
    }

    func testIncompleteSetupResumesExpectedSetupStep() {
        let state = OnboardingFeature.State(
            phoneNumber: BIRGEProductFixtures.Phones.incompletePassenger,
            passengerSetupStep: .routeDestination
        )

        XCTAssertEqual(state.step, .firstRouteEntry)
    }

    func testProfileFieldEditsUpdateState() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.fullNameChanged("Aruzhan S.")) {
            $0.fullName = "Aruzhan S."
        }
        await store.send(.cityChanged("Almaty")) {
            $0.city = "Almaty"
        }
        await store.send(.emailChanged("aruzhan@example.com")) {
            $0.email = "aruzhan@example.com"
        }
    }

    func testConsentTogglesUpdateState() async {
        let store = TestStore(initialState: OnboardingFeature.State(initialStep: .trustConsent)) {
            OnboardingFeature()
        }

        await store.send(.notificationsConsentToggled) {
            $0.notificationsConsent = true
        }
        await store.send(.locationConsentToggled) {
            $0.locationConsent = true
        }
        await store.send(.routePrivacyConsentToggled) {
            $0.routePrivacyConsent = true
        }
    }

    func testContinueFromProfileSavesProfileProgress() async {
        let savedDraft = LockIsolated<MockPassengerProfileBasicsDraft?>(nil)
        let savedProgress = LockIsolated<[PassengerSetupStep?]>([])

        let store = TestStore(
            initialState: OnboardingFeature.State(
                phoneNumber: BIRGEProductFixtures.Phones.unknownPassenger,
                fullName: "Aruzhan S.",
                city: "Almaty",
                email: "aruzhan@example.com"
            )
        ) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerProfileClient = Self.profileClient(
                onSaveProfile: { _, draft in savedDraft.withValue { $0 = draft } },
                onUpdateProgress: { _, step in savedProgress.withValue { $0.append(step) } }
            )
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(.profileSaveSucceeded) {
            $0.isSaving = false
            $0.step = .trustConsent
        }

        XCTAssertEqual(savedDraft.value?.fullName, "Aruzhan S.")
        XCTAssertEqual(savedDraft.value?.city, "Almaty")
        XCTAssertEqual(savedProgress.value, [.trustConsent])
    }

    func testContinueFromTrustSavesConsentProgress() async {
        let savedConsent = LockIsolated<MockPassengerConsentDraft?>(nil)
        let savedProgress = LockIsolated<[PassengerSetupStep?]>([])

        let store = TestStore(
            initialState: OnboardingFeature.State(
                phoneNumber: BIRGEProductFixtures.Phones.unknownPassenger,
                initialStep: .trustConsent,
                notificationsConsent: true,
                locationConsent: true,
                routePrivacyConsent: true
            )
        ) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerProfileClient = Self.profileClient(
                onSaveConsent: { _, draft in savedConsent.withValue { $0 = draft } },
                onUpdateProgress: { _, step in savedProgress.withValue { $0.append(step) } }
            )
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(.consentSaveSucceeded) {
            $0.isSaving = false
            $0.step = .productIntro
        }

        XCTAssertEqual(savedConsent.value?.notificationsConsent, true)
        XCTAssertEqual(savedConsent.value?.locationConsent, true)
        XCTAssertEqual(savedConsent.value?.routePrivacyConsent, true)
        XCTAssertEqual(savedProgress.value, [.productIntro])
    }

    func testProductIntroContinueReachesFirstRouteEntry() async {
        let savedProgress = LockIsolated<[PassengerSetupStep?]>([])

        let store = TestStore(
            initialState: OnboardingFeature.State(
                phoneNumber: BIRGEProductFixtures.Phones.unknownPassenger,
                initialStep: .productIntro
            )
        ) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerProfileClient = Self.profileClient(
                onUpdateProgress: { _, step in savedProgress.withValue { $0.append(step) } }
            )
            $0.passengerRouteClient = Self.routeClient()
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(.productIntroSaveSucceeded(BIRGEProductFixtures.Passenger.draftRoute)) {
            $0.isSaving = false
            $0.productIntroCompleted = true
            $0.routeDraft = BIRGEProductFixtures.Passenger.draftRoute
            $0.step = .firstRouteEntry
        }

        XCTAssertEqual(savedProgress.value, [.routeOrigin])
    }

    func testBackNavigationMovesToPreviousStep() async {
        let store = TestStore(initialState: OnboardingFeature.State(initialStep: .firstRouteEntry)) {
            OnboardingFeature()
        }

        await store.send(.backTapped) {
            $0.step = .productIntro
        }
        await store.send(.backTapped) {
            $0.step = .trustConsent
        }
        await store.send(.backTapped) {
            $0.step = .profileBasics
        }
        await store.send(.backTapped)
    }

    func testOriginQueryLoadsAddressResults() async {
        let origin = BIRGEProductFixtures.Passenger.addressSearchResults[0]
        let store = TestStore(initialState: OnboardingFeature.State(initialStep: .firstRouteEntry)) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(addressResults: [origin])
        }

        await store.send(.originQueryChanged("Alatau")) {
            $0.originAddressQuery = "Alatau"
            $0.isLoadingRouteData = true
        }
        await store.receive(.originAddressResultsLoaded([origin])) {
            $0.isLoadingRouteData = false
            $0.originAddressResults = [origin]
        }
    }

    func testOriginQueryChangesOnlyOriginState() async {
        let destination = BIRGEProductFixtures.Passenger.addressSearchResults[1]
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            destinationAddressQuery: "Existing destination",
            destinationAddressResults: [destination],
            selectedDestinationAddress: destination
        )) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(addressResults: [BIRGEProductFixtures.Passenger.addressSearchResults[0]])
        }

        await store.send(.originQueryChanged("Alatau")) {
            $0.originAddressQuery = "Alatau"
            $0.isLoadingRouteData = true
        }
        await store.receive(.originAddressResultsLoaded([BIRGEProductFixtures.Passenger.addressSearchResults[0]])) {
            $0.isLoadingRouteData = false
            $0.originAddressResults = [BIRGEProductFixtures.Passenger.addressSearchResults[0]]
        }

        XCTAssertEqual(store.state.destinationAddressQuery, "Existing destination")
        XCTAssertEqual(store.state.destinationAddressResults, [destination])
        XCTAssertEqual(store.state.selectedDestinationAddress, destination)
    }

    func testCannotAdvanceToPickupNodeBeforeSelectingOriginAddress() async {
        let store = TestStore(initialState: OnboardingFeature.State(initialStep: .firstRouteEntry)) {
            OnboardingFeature()
        }

        await store.send(.continueTapped)
    }

    func testSelectingOriginLoadsPickupNodeSuggestions() async {
        let origin = BIRGEProductFixtures.Passenger.addressSearchResults[0]
        let pickupNodes = BIRGEProductFixtures.Passenger.pickupNodes
        let store = TestStore(initialState: OnboardingFeature.State(initialStep: .firstRouteEntry)) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(pickupNodes: pickupNodes)
        }

        await store.send(.originAddressSelected(origin)) {
            $0.selectedOriginAddress = origin
            $0.originAddressQuery = origin.fullAddress
            $0.isLoadingRouteData = true
        }
        await store.receive(.pickupNodesLoaded(pickupNodes)) {
            $0.isLoadingRouteData = false
            $0.suggestedPickupNodes = pickupNodes
        }
    }

    func testOriginSelectionEnablesAndAdvancesToPickupNode() async {
        let origin = BIRGEProductFixtures.Passenger.addressSearchResults[0]
        let pickupNodes = BIRGEProductFixtures.Passenger.pickupNodes
        let store = TestStore(initialState: OnboardingFeature.State(initialStep: .firstRouteEntry)) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(pickupNodes: pickupNodes)
        }

        await store.send(.originAddressSelected(origin)) {
            $0.selectedOriginAddress = origin
            $0.originAddressQuery = origin.fullAddress
            $0.isLoadingRouteData = true
        }
        await store.receive(.pickupNodesLoaded(pickupNodes)) {
            $0.isLoadingRouteData = false
            $0.suggestedPickupNodes = pickupNodes
        }

        XCTAssertTrue(store.state.canContinue)
        await store.send(.continueTapped) {
            $0.routeStep = .pickupNode
        }
    }

    func testCannotAdvanceToDestinationBeforeSelectingPickupNode() async {
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .pickupNode,
            suggestedPickupNodes: BIRGEProductFixtures.Passenger.pickupNodes
        )) {
            OnboardingFeature()
        }

        await store.send(.continueTapped)
    }

    func testDestinationQueryLoadsAddressResults() async {
        let destination = BIRGEProductFixtures.Passenger.addressSearchResults[1]
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .destinationAddress
        )) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(addressResults: [destination])
        }

        await store.send(.destinationQueryChanged("Esentai")) {
            $0.destinationAddressQuery = "Esentai"
            $0.isLoadingRouteData = true
        }
        await store.receive(.destinationAddressResultsLoaded([destination])) {
            $0.isLoadingRouteData = false
            $0.destinationAddressResults = [destination]
        }
    }

    func testDestinationQueryDoesNotMutateOriginState() async {
        let origin = BIRGEProductFixtures.Passenger.addressSearchResults[0]
        let destination = BIRGEProductFixtures.Passenger.addressSearchResults[1]
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .destinationAddress,
            originAddressQuery: origin.fullAddress,
            originAddressResults: [origin],
            selectedOriginAddress: origin,
            suggestedPickupNodes: BIRGEProductFixtures.Passenger.pickupNodes,
            selectedPickupNodeID: BIRGEProductFixtures.Passenger.pickupNodes[0].id
        )) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(addressResults: [destination])
        }

        await store.send(.destinationQueryChanged("Esentai")) {
            $0.destinationAddressQuery = "Esentai"
            $0.isLoadingRouteData = true
        }
        await store.receive(.destinationAddressResultsLoaded([destination])) {
            $0.isLoadingRouteData = false
            $0.destinationAddressResults = [destination]
        }

        XCTAssertEqual(store.state.originAddressQuery, origin.fullAddress)
        XCTAssertEqual(store.state.originAddressResults, [origin])
        XCTAssertEqual(store.state.selectedOriginAddress, origin)
        XCTAssertEqual(store.state.selectedPickupNodeID, BIRGEProductFixtures.Passenger.pickupNodes[0].id)
    }

    func testSelectingDestinationLoadsDropoffNodeSuggestions() async {
        let destination = BIRGEProductFixtures.Passenger.addressSearchResults[1]
        let dropoffNodes = BIRGEProductFixtures.Passenger.dropoffNodes
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .destinationAddress
        )) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(dropoffNodes: dropoffNodes)
        }

        await store.send(.destinationAddressSelected(destination)) {
            $0.selectedDestinationAddress = destination
            $0.destinationAddressQuery = destination.fullAddress
            $0.isLoadingRouteData = true
        }
        await store.receive(.dropoffNodesLoaded(dropoffNodes)) {
            $0.isLoadingRouteData = false
            $0.suggestedDropoffNodes = dropoffNodes
        }
    }

    func testDestinationSelectionEnablesAndAdvancesToDropoffNode() async {
        let destination = BIRGEProductFixtures.Passenger.addressSearchResults[1]
        let dropoffNodes = BIRGEProductFixtures.Passenger.dropoffNodes
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .destinationAddress
        )) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(dropoffNodes: dropoffNodes)
        }

        await store.send(.destinationAddressSelected(destination)) {
            $0.selectedDestinationAddress = destination
            $0.destinationAddressQuery = destination.fullAddress
            $0.isLoadingRouteData = true
        }
        await store.receive(.dropoffNodesLoaded(dropoffNodes)) {
            $0.isLoadingRouteData = false
            $0.suggestedDropoffNodes = dropoffNodes
        }

        XCTAssertTrue(store.state.canContinue)
        await store.send(.continueTapped) {
            $0.routeStep = .dropoffNode
        }
    }

    func testCannotAdvanceToScheduleBeforeSelectingDropoffNode() async {
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .dropoffNode,
            suggestedDropoffNodes: BIRGEProductFixtures.Passenger.dropoffNodes
        )) {
            OnboardingFeature()
        }

        await store.send(.continueTapped)
    }

    func testWeekdayTogglesUpdateScheduleState() async {
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .schedule
        )) {
            OnboardingFeature()
        }

        await store.send(.weekdayToggled("mon")) {
            $0.selectedWeekdays = ["mon"]
        }
        await store.send(.weekdayToggled("mon")) {
            $0.selectedWeekdays = []
        }
    }

    func testDepartureAndFlexibilityUpdateRouteWindow() async {
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .schedule
        )) {
            OnboardingFeature()
        }

        await store.send(.departureTimeChanged("07:20")) {
            $0.departureTime = "07:20"
        }
        await store.send(.flexibilityMinutesChanged(25)) {
            $0.flexibilityMinutes = 25
        }
        XCTAssertEqual(store.state.departureWindowEnd, "07:45")
    }

    func testTimePickerHourAndMinuteChangesUpdateDepartureTime() async {
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .schedule,
            departureTime: "07:45"
        )) {
            OnboardingFeature()
        }

        await store.send(.departureHourChanged(8)) {
            $0.departureTime = "08:45"
        }
        await store.send(.departureMinuteChanged(30)) {
            $0.departureTime = "08:30"
        }
    }

    func testSetupProgressIndexAndCountAreConsistent() {
        XCTAssertEqual(OnboardingFeature.State.progressStepCount, 9)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .profileBasics, routeStep: .originAddress), 1)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .trustConsent, routeStep: .originAddress), 2)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .productIntro, routeStep: .originAddress), 3)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .firstRouteEntry, routeStep: .originAddress), 4)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .firstRouteEntry, routeStep: .pickupNode), 5)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .firstRouteEntry, routeStep: .destinationAddress), 6)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .firstRouteEntry, routeStep: .dropoffNode), 7)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .firstRouteEntry, routeStep: .schedule), 8)
        XCTAssertEqual(OnboardingFeature.State.progressStepIndex(step: .firstRouteEntry, routeStep: .review), 9)
    }

    func testRouteReviewSaveCallsMockClientAndDelegatesToSubscription() async {
        let savedDrafts = LockIsolated<[MockRouteDraft]>([])
        let origin = BIRGEProductFixtures.Passenger.addressSearchResults[0]
        let destination = BIRGEProductFixtures.Passenger.addressSearchResults[1]
        let pickup = BIRGEProductFixtures.Passenger.pickupNodes[0]
        let dropoff = BIRGEProductFixtures.Passenger.dropoffNodes[0]
        let initialState = OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .review,
            routeDraft: BIRGEProductFixtures.Passenger.draftRoute,
            selectedOriginAddress: origin,
            suggestedPickupNodes: [pickup],
            selectedPickupNodeID: pickup.id,
            selectedDestinationAddress: destination,
            suggestedDropoffNodes: [dropoff],
            selectedDropoffNodeID: dropoff.id,
            selectedWeekdays: ["mon", "tue"],
            departureTime: "07:20",
            flexibilityMinutes: 25
        )
        let expectedDraft = initialState.routeDraftForReview!

        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        } withDependencies: {
            $0.passengerRouteClient = Self.routeClient(
                onSaveRouteDraft: { draft in
                    savedDrafts.withValue { $0.append(draft) }
                    return draft
                }
            )
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(.routeDraftSaveSucceeded(expectedDraft)) {
            $0.isSaving = false
            $0.routeDraft = expectedDraft
        }
        await store.receive(.delegate(.routeDraftReadyForSubscription(expectedDraft)))

        XCTAssertEqual(savedDrafts.value, [expectedDraft])
    }

    func testRouteBackNavigationMovesThroughRouteSteps() async {
        let store = TestStore(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .review
        )) {
            OnboardingFeature()
        }

        await store.send(.backTapped) {
            $0.routeStep = .schedule
        }
        await store.send(.backTapped) {
            $0.routeStep = .dropoffNode
        }
        await store.send(.backTapped) {
            $0.routeStep = .destinationAddress
        }
        await store.send(.backTapped) {
            $0.routeStep = .pickupNode
        }
        await store.send(.backTapped) {
            $0.routeStep = .originAddress
        }
        await store.send(.backTapped) {
            $0.step = .productIntro
        }
    }

    private static func profileClient(
        onSaveProfile: @escaping @Sendable (String, MockPassengerProfileBasicsDraft) async throws -> Void = { _, _ in },
        onSaveConsent: @escaping @Sendable (String, MockPassengerConsentDraft) async throws -> Void = { _, _ in },
        onUpdateProgress: @escaping @Sendable (String, PassengerSetupStep?) async throws -> Void = { _, _ in }
    ) -> PassengerProfileClient {
        PassengerProfileClient(
            profile: { _ in BIRGEProductFixtures.Passenger.profiles[0] },
            onboardingStep: { _ in nil },
            saveProfileBasics: onSaveProfile,
            saveTrustConsent: onSaveConsent,
            updateOnboardingProgress: onUpdateProgress
        )
    }

    private static func routeClient(
        addressResults: [MockAddressSearchResult] = BIRGEProductFixtures.Passenger.addressSearchResults,
        pickupNodes: [MockCommuteNode] = BIRGEProductFixtures.Passenger.pickupNodes,
        dropoffNodes: [MockCommuteNode] = BIRGEProductFixtures.Passenger.dropoffNodes,
        onSaveRouteDraft: @escaping @Sendable (MockRouteDraft) async throws -> MockRouteDraft = { $0 }
    ) -> PassengerRouteClient {
        PassengerRouteClient(
            draftRoute: { BIRGEProductFixtures.Passenger.draftRoute },
            searchAddresses: { _ in addressResults },
            suggestedPickupNodes: { _ in pickupNodes },
            suggestedDropoffNodes: { _ in dropoffNodes },
            saveRouteDraft: onSaveRouteDraft,
            homeDashboard: { BIRGEProductFixtures.Passenger.homeDashboard },
            todayCommutePlan: { BIRGEProductFixtures.Passenger.todayCommutePlan },
            recurringRoutes: { BIRGEProductFixtures.Passenger.recurringRoutes },
            routeDetail: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
            pauseRoute: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
            resumeRoute: { _ in BIRGEProductFixtures.Passenger.recurringRoutes[0] },
            plannedRide: { _ in BIRGEProductFixtures.Passenger.plannedCommuteRide },
            todayPlannedRide: { BIRGEProductFixtures.Passenger.plannedCommuteRide },
            advancePlannedRideStatus: { _, status in
                var ride = BIRGEProductFixtures.Passenger.plannedCommuteRide
                ride.status = status
                return ride
            },
            rideDayTimelines: { BIRGEProductFixtures.Passenger.rideDayTimelines }
        )
    }
}
