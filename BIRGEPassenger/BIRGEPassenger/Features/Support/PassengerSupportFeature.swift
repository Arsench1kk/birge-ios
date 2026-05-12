import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct PassengerSupportFeature {
    @ObservableState
    struct State: Equatable {
        enum Mode: Equatable, Sendable {
            case inbox
            case ticketDetail
            case liveSupport
            case issueReport
            case safetyCenter
            case shareStatus
        }

        var mode: Mode
        var context: MockSupportContext?
        var tickets: [MockSupportTicket] = []
        var selectedTicket: MockSupportTicket?
        var selectedTicketMessages: [MockSupportMessage] = []
        var liveSupportSession: MockLiveSupportSession?
        var issueCategories: [MockIssueCategory] = []
        var issueDraft: MockIssueReportDraft
        var submittedIssueTicket: MockSupportTicket?
        var safetyContacts: [MockSafetyContact] = []
        var contactDraft: MockSafetyContactDraft?
        var shareStatusSession: MockShareStatusSession?
        var isLoading = false
        var isSubmitting = false
        var errorMessage: String?

        init(
            mode: Mode = .inbox,
            context: MockSupportContext? = nil
        ) {
            self.mode = mode
            self.context = context
            self.issueDraft = MockIssueReportDraft(
                id: UUID(uuidString: "91000000-0000-0000-0000-000000000001")!,
                context: context
            )
        }
    }

    enum Action: ViewAction, Equatable, Sendable {
        case view(View)
        case supportInboxLoaded([MockSupportTicket], [MockIssueCategory], [MockSafetyContact])
        case supportLoadFailed(String)
        case ticketDetailLoaded(MockSupportTicket, [MockSupportMessage])
        case issueReportSubmitted(MockSupportTicket)
        case liveSupportStarted(MockLiveSupportSession)
        case safetyContactsLoaded([MockSafetyContact])
        case safetyContactSaved(MockSafetyContact)
        case safetyContactRemoved(MockSafetyContact.ID)
        case shareStatusSessionCreated(MockShareStatusSession)
        case delegate(Delegate)

        @CasePathable
        enum View: Equatable, Sendable {
            case onAppear
            case ticketSelected(MockSupportTicket.ID)
            case startLiveSupportTapped
            case openIssueReportTapped
            case issueCategorySelected(MockIssueCategory.ID)
            case issueDescriptionChanged(String)
            case submitIssueReportTapped
            case openSafetyCenterTapped
            case shareRouteStatusTapped
            case addEmergencyContactTapped
            case editEmergencyContactTapped(MockSafetyContact.ID)
            case contactNameChanged(String)
            case contactPhoneChanged(String)
            case contactRelationshipChanged(String)
            case saveEmergencyContactTapped
            case removeEmergencyContactTapped(MockSafetyContact.ID)
            case backTapped
            case doneTapped
        }

        @CasePathable
        enum Delegate: Equatable, Sendable {
            case done
            case back
        }
    }

    @Dependency(\.passengerSupportClient) var passengerSupportClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.isLoading = true
                state.errorMessage = nil
                let mode = state.mode
                let context = state.context
                let loadEffect: Effect<Action> = .run { send in
                    do {
                        let tickets = try await passengerSupportClient.fetchSupportInbox()
                        let categories = await passengerSupportClient.issueCategories()
                        let contacts = try await passengerSupportClient.fetchSafetyContacts()
                        await send(.supportInboxLoaded(tickets, categories, contacts))
                    } catch {
                        await send(.supportLoadFailed(error.localizedDescription))
                    }
                }
                guard mode == .shareStatus else { return loadEffect }
                state.isSubmitting = true
                return .merge(
                    loadEffect,
                    .run { send in
                        do {
                            let session = try await passengerSupportClient.createShareStatusSession(context)
                            await send(.shareStatusSessionCreated(session))
                        } catch {
                            await send(.supportLoadFailed(error.localizedDescription))
                        }
                    }
                )

            case let .view(.ticketSelected(ticketID)):
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let (ticket, messages) = try await passengerSupportClient.fetchTicketDetail(ticketID)
                        await send(.ticketDetailLoaded(ticket, messages))
                    } catch {
                        await send(.supportLoadFailed(error.localizedDescription))
                    }
                }

            case .view(.startLiveSupportTapped):
                state.isSubmitting = true
                state.errorMessage = nil
                let context = state.context
                return .run { send in
                    do {
                        let session = try await passengerSupportClient.startLiveSupport(context)
                        await send(.liveSupportStarted(session))
                    } catch {
                        await send(.supportLoadFailed(error.localizedDescription))
                    }
                }

            case .view(.openIssueReportTapped):
                state.mode = .issueReport
                return .none

            case let .view(.issueCategorySelected(categoryID)):
                state.issueDraft.categoryID = categoryID
                return .none

            case let .view(.issueDescriptionChanged(description)):
                state.issueDraft.description = description
                return .none

            case .view(.submitIssueReportTapped):
                state.isSubmitting = true
                state.errorMessage = nil
                let draft = state.issueDraft
                return .run { send in
                    do {
                        let ticket = try await passengerSupportClient.submitIssueReport(draft)
                        await send(.issueReportSubmitted(ticket))
                    } catch {
                        await send(.supportLoadFailed(error.localizedDescription))
                    }
                }

            case .view(.openSafetyCenterTapped):
                state.mode = .safetyCenter
                return .none

            case .view(.shareRouteStatusTapped):
                state.isSubmitting = true
                state.errorMessage = nil
                let context = state.context
                return .run { send in
                    do {
                        let session = try await passengerSupportClient.createShareStatusSession(context)
                        await send(.shareStatusSessionCreated(session))
                    } catch {
                        await send(.supportLoadFailed(error.localizedDescription))
                    }
                }

            case .view(.addEmergencyContactTapped):
                state.contactDraft = MockSafetyContactDraft()
                return .none

            case let .view(.editEmergencyContactTapped(contactID)):
                guard let contact = state.safetyContacts.first(where: { $0.id == contactID }) else {
                    return .none
                }
                state.contactDraft = MockSafetyContactDraft(
                    id: contact.id,
                    name: contact.name,
                    phoneNumber: contact.phoneNumber,
                    relationship: contact.relationship
                )
                return .none

            case let .view(.contactNameChanged(name)):
                state.contactDraft?.name = name
                return .none

            case let .view(.contactPhoneChanged(phone)):
                state.contactDraft?.phoneNumber = phone
                return .none

            case let .view(.contactRelationshipChanged(relationship)):
                state.contactDraft?.relationship = relationship
                return .none

            case .view(.saveEmergencyContactTapped):
                guard let draft = state.contactDraft else { return .none }
                state.isSubmitting = true
                state.errorMessage = nil
                let contact = MockSafetyContact(
                    id: draft.id ?? UUID(),
                    name: draft.name,
                    phoneNumber: draft.phoneNumber,
                    relationship: draft.relationship
                )
                return .run { send in
                    do {
                        let saved = try await passengerSupportClient.saveSafetyContact(contact)
                        await send(.safetyContactSaved(saved))
                    } catch {
                        await send(.supportLoadFailed(error.localizedDescription))
                    }
                }

            case let .view(.removeEmergencyContactTapped(contactID)):
                state.isSubmitting = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        try await passengerSupportClient.removeSafetyContact(contactID)
                        await send(.safetyContactRemoved(contactID))
                    } catch {
                        await send(.supportLoadFailed(error.localizedDescription))
                    }
                }

            case .view(.backTapped):
                return .send(.delegate(.back))

            case .view(.doneTapped):
                return .send(.delegate(.done))

            case let .supportInboxLoaded(tickets, categories, contacts):
                state.isLoading = false
                state.errorMessage = nil
                state.tickets = tickets
                state.issueCategories = categories
                state.safetyContacts = contacts
                return .none

            case let .supportLoadFailed(message):
                state.isLoading = false
                state.isSubmitting = false
                state.errorMessage = message
                return .none

            case let .ticketDetailLoaded(ticket, messages):
                state.isLoading = false
                state.mode = .ticketDetail
                state.selectedTicket = ticket
                state.selectedTicketMessages = messages
                return .none

            case let .issueReportSubmitted(ticket):
                state.isSubmitting = false
                state.submittedIssueTicket = ticket
                state.tickets.insert(ticket, at: 0)
                return .none

            case let .liveSupportStarted(session):
                state.isSubmitting = false
                state.mode = .liveSupport
                state.liveSupportSession = session
                return .none

            case let .safetyContactsLoaded(contacts):
                state.isLoading = false
                state.safetyContacts = contacts
                return .none

            case let .safetyContactSaved(contact):
                state.isSubmitting = false
                state.contactDraft = nil
                if let index = state.safetyContacts.firstIndex(where: { $0.id == contact.id }) {
                    state.safetyContacts[index] = contact
                } else {
                    state.safetyContacts.append(contact)
                }
                return .none

            case let .safetyContactRemoved(contactID):
                state.isSubmitting = false
                state.safetyContacts.removeAll { $0.id == contactID }
                return .none

            case let .shareStatusSessionCreated(session):
                state.isSubmitting = false
                state.mode = .shareStatus
                state.shareStatusSession = session
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
