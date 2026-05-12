import BIRGECore
import ComposableArchitecture
import SwiftUI

@ViewAction(for: PassengerSupportFeature.self)
struct PassengerSupportView: View {
    @Bindable var store: StoreOf<PassengerSupportFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BIRGELayout.m) {
                if store.isLoading {
                    ProgressView()
                }

                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.danger)
                }

                switch store.mode {
                case .inbox:
                    inbox
                case .ticketDetail:
                    ticketDetail
                case .liveSupport:
                    liveSupport
                case .issueReport:
                    issueReport
                case .safetyCenter:
                    safetyCenter
                case .shareStatus:
                    shareStatus
                }
            }
            .padding(BIRGELayout.m)
        }
        .background(BIRGEColors.background.ignoresSafeArea())
        .navigationTitle("Support")
        .task {
            send(.onAppear)
        }
    }

    private var inbox: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            ForEach(store.tickets) { ticket in
                Button {
                    send(.ticketSelected(ticket.id))
                } label: {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(ticket.title)
                            .font(BIRGEFonts.bodyMedium)
                        Text(ticket.status.rawValue)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                        Text(ticket.updatedAtLabel)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }

            Button("Live support") { send(.startLiveSupportTapped) }
            Button("Report issue") { send(.openIssueReportTapped) }
            Button("Safety") { send(.openSafetyCenterTapped) }
            Button("Share status") { send(.shareRouteStatusTapped) }
        }
    }

    @ViewBuilder
    private var ticketDetail: some View {
        if let ticket = store.selectedTicket {
            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                Text(ticket.title)
                    .font(BIRGEFonts.title)
                Text(ticket.status.rawValue)
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.brandPrimary)

                ForEach(store.selectedTicketMessages) { message in
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(message.senderTitle)
                            .font(BIRGEFonts.bodyMedium)
                        Text(message.body)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                        Text(message.sentAtLabel)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textTertiary)
                    }
                }
            }
        }
    }

    private var liveSupport: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            if let session = store.liveSupportSession {
                Text(session.title)
                    .font(BIRGEFonts.title)
                Text(session.status)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            Button("Done") { send(.doneTapped) }
        }
    }

    private var issueReport: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            ForEach(store.issueCategories) { category in
                Button {
                    send(.issueCategorySelected(category.id))
                } label: {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(category.title)
                            .font(BIRGEFonts.bodyMedium)
                        Text(category.contextHint)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }

            TextField("Details", text: Binding(
                get: { store.issueDraft.description },
                set: { send(.issueDescriptionChanged($0)) }
            ))
                .textFieldStyle(.roundedBorder)

            Button("Submit") { send(.submitIssueReportTapped) }
                .buttonStyle(.borderedProminent)

            if let ticket = store.submittedIssueTicket {
                Text(ticket.title)
                    .font(BIRGEFonts.captionBold)
            }
        }
    }

    private var safetyCenter: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            ForEach(store.safetyContacts) { contact in
                HStack {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(contact.name)
                            .font(BIRGEFonts.bodyMedium)
                        Text(contact.relationship)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                        Text(contact.phoneNumber)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textTertiary)
                    }
                    Spacer()
                    Button("Edit") { send(.editEmergencyContactTapped(contact.id)) }
                    Button("Remove") { send(.removeEmergencyContactTapped(contact.id)) }
                }
            }

            Button("Add contact") { send(.addEmergencyContactTapped) }

            if store.contactDraft != nil {
                TextField("Name", text: Binding(
                    get: { store.contactDraft?.name ?? "" },
                    set: { send(.contactNameChanged($0)) }
                ))
                .textFieldStyle(.roundedBorder)

                TextField("Phone", text: Binding(
                    get: { store.contactDraft?.phoneNumber ?? "" },
                    set: { send(.contactPhoneChanged($0)) }
                ))
                .textFieldStyle(.roundedBorder)

                TextField("Relationship", text: Binding(
                    get: { store.contactDraft?.relationship ?? "" },
                    set: { send(.contactRelationshipChanged($0)) }
                ))
                .textFieldStyle(.roundedBorder)

                Button("Save") { send(.saveEmergencyContactTapped) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var shareStatus: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            if let session = store.shareStatusSession {
                Text(session.title)
                    .font(BIRGEFonts.title)
                Text(session.statusText)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Text(session.expiresAtLabel)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textTertiary)
            }
            Button("Done") { send(.doneTapped) }
        }
    }
}

#Preview {
    PassengerSupportView(
        store: Store(initialState: PassengerSupportFeature.State()) {
            PassengerSupportFeature()
        }
    )
}
