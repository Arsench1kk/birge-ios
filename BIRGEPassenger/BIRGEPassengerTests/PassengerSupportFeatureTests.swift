import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class PassengerSupportFeatureTests: XCTestCase {
    func testSupportInboxLoadsTickets() async {
        let tickets = BIRGEProductFixtures.Passenger.supportTickets
        let categories = BIRGEProductFixtures.Passenger.issueCategories
        let contacts = BIRGEProductFixtures.Passenger.safetyContacts
        let store = TestStore(initialState: PassengerSupportFeature.State()) {
            PassengerSupportFeature()
        } withDependencies: {
            $0.passengerSupportClient = Self.supportClient()
        }

        await store.send(.view(.onAppear)) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.supportInboxLoaded(tickets, categories, contacts)) {
            $0.isLoading = false
            $0.tickets = tickets
            $0.issueCategories = categories
            $0.safetyContacts = contacts
        }
    }

    func testSelectingTicketLoadsDetail() async {
        let ticket = BIRGEProductFixtures.Passenger.supportTickets[0]
        let messages = BIRGEProductFixtures.Passenger.supportMessages.filter { $0.ticketID == ticket.id }
        var state = PassengerSupportFeature.State()
        state.tickets = [ticket]
        let store = TestStore(initialState: state) {
            PassengerSupportFeature()
        } withDependencies: {
            $0.passengerSupportClient = Self.supportClient()
        }

        await store.send(.view(.ticketSelected(ticket.id))) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.ticketDetailLoaded(ticket, messages)) {
            $0.isLoading = false
            $0.mode = .ticketDetail
            $0.selectedTicket = ticket
            $0.selectedTicketMessages = messages
        }
    }

    func testIssueCategorySelectionUpdatesDraft() async {
        let category = BIRGEProductFixtures.Passenger.issueCategories[0]
        let store = TestStore(initialState: PassengerSupportFeature.State(mode: .issueReport)) {
            PassengerSupportFeature()
        }

        await store.send(.view(.issueCategorySelected(category.id))) {
            $0.issueDraft.categoryID = category.id
        }
    }

    func testIssueDescriptionUpdatesDraft() async {
        let store = TestStore(initialState: PassengerSupportFeature.State(mode: .issueReport)) {
            PassengerSupportFeature()
        }

        await store.send(.view(.issueDescriptionChanged("Pickup was late"))) {
            $0.issueDraft.description = "Pickup was late"
        }
    }

    func testSubmittingIssueReportSucceeds() async {
        let ticket = BIRGEProductFixtures.Passenger.supportTickets[0]
        var state = PassengerSupportFeature.State(
            mode: .issueReport,
            context: BIRGEProductFixtures.Passenger.supportContext
        )
        state.issueDraft.categoryID = BIRGEProductFixtures.Passenger.issueCategories[0].id
        state.issueDraft.description = "Driver timing issue"
        let store = TestStore(initialState: state) {
            PassengerSupportFeature()
        } withDependencies: {
            $0.passengerSupportClient = Self.supportClient(submittedTicket: ticket)
        }

        await store.send(.view(.submitIssueReportTapped)) {
            $0.isSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(.issueReportSubmitted(ticket)) {
            $0.isSubmitting = false
            $0.submittedIssueTicket = ticket
            $0.tickets = [ticket]
        }
    }

    func testSubmittingIssueReportFailureStoresErrorState() async {
        var state = PassengerSupportFeature.State(mode: .issueReport)
        state.issueDraft.description = "Cannot submit"
        let store = TestStore(initialState: state) {
            PassengerSupportFeature()
        } withDependencies: {
            $0.passengerSupportClient = Self.supportClient(
                submitIssue: { _ in throw MockFrontendError("Submit failed.") }
            )
        }

        await store.send(.view(.submitIssueReportTapped)) {
            $0.isSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(.supportLoadFailed("Submit failed.")) {
            $0.isSubmitting = false
            $0.errorMessage = "Submit failed."
        }
    }

    func testStartLiveSupportCreatesPlaceholderSession() async {
        let session = BIRGEProductFixtures.Passenger.liveSupportSession
        let store = TestStore(initialState: PassengerSupportFeature.State(context: BIRGEProductFixtures.Passenger.supportContext)) {
            PassengerSupportFeature()
        } withDependencies: {
            $0.passengerSupportClient = Self.supportClient(liveSession: session)
        }

        await store.send(.view(.startLiveSupportTapped)) {
            $0.isSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(.liveSupportStarted(session)) {
            $0.isSubmitting = false
            $0.mode = .liveSupport
            $0.liveSupportSession = session
        }
    }

    func testSafetyCenterOpens() async {
        let store = TestStore(initialState: PassengerSupportFeature.State()) {
            PassengerSupportFeature()
        }

        await store.send(.view(.openSafetyCenterTapped)) {
            $0.mode = .safetyCenter
        }
    }

    func testShareStatusCreatesMockSession() async {
        let session = BIRGEProductFixtures.Passenger.shareStatusSession
        let store = TestStore(initialState: PassengerSupportFeature.State(context: BIRGEProductFixtures.Passenger.supportContext)) {
            PassengerSupportFeature()
        } withDependencies: {
            $0.passengerSupportClient = Self.supportClient(shareSession: session)
        }

        await store.send(.view(.shareRouteStatusTapped)) {
            $0.isSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(.shareStatusSessionCreated(session)) {
            $0.isSubmitting = false
            $0.mode = .shareStatus
            $0.shareStatusSession = session
        }
    }

    func testAddEditRemoveEmergencyContactUpdatesState() async {
        let contact = BIRGEProductFixtures.Passenger.safetyContacts[0]
        let saved = MockSafetyContact(
            id: contact.id,
            name: "Updated",
            phoneNumber: "+77770000102",
            relationship: "Friend"
        )
        var state = PassengerSupportFeature.State(mode: .safetyCenter)
        state.safetyContacts = [contact]
        let store = TestStore(initialState: state) {
            PassengerSupportFeature()
        } withDependencies: {
            $0.passengerSupportClient = Self.supportClient(savedContact: saved)
        }

        await store.send(.view(.addEmergencyContactTapped)) {
            $0.contactDraft = MockSafetyContactDraft()
        }
        await store.send(.view(.contactNameChanged("Updated"))) {
            $0.contactDraft?.name = "Updated"
        }
        await store.send(.view(.editEmergencyContactTapped(contact.id))) {
            $0.contactDraft = MockSafetyContactDraft(
                id: contact.id,
                name: contact.name,
                phoneNumber: contact.phoneNumber,
                relationship: contact.relationship
            )
        }
        await store.send(.view(.contactNameChanged(saved.name))) {
            $0.contactDraft?.name = saved.name
        }
        await store.send(.view(.contactPhoneChanged(saved.phoneNumber))) {
            $0.contactDraft?.phoneNumber = saved.phoneNumber
        }
        await store.send(.view(.contactRelationshipChanged(saved.relationship))) {
            $0.contactDraft?.relationship = saved.relationship
        }
        await store.send(.view(.saveEmergencyContactTapped)) {
            $0.isSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(.safetyContactSaved(saved)) {
            $0.isSubmitting = false
            $0.contactDraft = nil
            $0.safetyContacts = [saved]
        }
        await store.send(.view(.removeEmergencyContactTapped(saved.id))) {
            $0.isSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(.safetyContactRemoved(saved.id)) {
            $0.isSubmitting = false
            $0.safetyContacts = []
        }
    }

    private static func supportClient(
        submittedTicket: MockSupportTicket = BIRGEProductFixtures.Passenger.supportTickets[0],
        liveSession: MockLiveSupportSession = BIRGEProductFixtures.Passenger.liveSupportSession,
        shareSession: MockShareStatusSession = BIRGEProductFixtures.Passenger.shareStatusSession,
        savedContact: MockSafetyContact = BIRGEProductFixtures.Passenger.safetyContacts[0],
        submitIssue: @escaping @Sendable (_ draft: MockIssueReportDraft) async throws -> MockSupportTicket = { _ in
            BIRGEProductFixtures.Passenger.supportTickets[0]
        }
    ) -> PassengerSupportClient {
        PassengerSupportClient(
            fetchSupportInbox: { BIRGEProductFixtures.Passenger.supportTickets },
            fetchTicketDetail: { ticketID in
                guard let ticket = BIRGEProductFixtures.Passenger.supportTickets.first(where: { $0.id == ticketID }) else {
                    throw MockFrontendError("Support ticket not found.")
                }
                return (
                    ticket,
                    BIRGEProductFixtures.Passenger.supportMessages.filter { $0.ticketID == ticketID }
                )
            },
            issueCategories: { BIRGEProductFixtures.Passenger.issueCategories },
            submitIssueReport: { draft in
                if submittedTicket.id == BIRGEProductFixtures.Passenger.supportTickets[0].id {
                    return try await submitIssue(draft)
                }
                return submittedTicket
            },
            startLiveSupport: { _ in liveSession },
            fetchSafetyContacts: { BIRGEProductFixtures.Passenger.safetyContacts },
            saveSafetyContact: { _ in savedContact },
            removeSafetyContact: { _ in },
            createShareStatusSession: { _ in shareSession }
        )
    }
}
