import BIRGECore
import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                setupHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: BIRGELayout.m) {
                        stepContent

                        if let errorMessage = store.errorMessage {
                            ErrorBanner(message: errorMessage)
                                .accessibilityIdentifier("passenger_setup_error")
                        }
                    }
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.top, BIRGELayout.s)
                    .padding(.bottom, BIRGELayout.xxl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                footer
            }
            .background(BIRGEColors.passengerBackground.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch store.step {
        case .profileBasics:
            ProfileBasicsStepView(store: store)
        case .trustConsent:
            TrustConsentStepView(store: store)
        case .productIntro:
            ProductIntroStepView()
        case .firstRouteEntry:
            routeStepContent
        }
    }

    @ViewBuilder
    private var routeStepContent: some View {
        switch store.routeStep {
        case .originAddress:
            RouteOriginStepView(store: store)
        case .pickupNode:
            PickupNodeStepView(store: store)
        case .destinationAddress:
            RouteDestinationStepView(store: store)
        case .dropoffNode:
            DropoffNodeStepView(store: store)
        case .schedule:
            RouteScheduleStepView(store: store)
        case .review:
            RouteReviewStepView(store: store)
        }
    }

    private var setupHeader: some View {
        VStack(spacing: BIRGELayout.xs) {
            HStack {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(store.canGoBack ? BIRGEColors.textPrimary : BIRGEColors.textDisabled)
                        .frame(width: 44, height: 44)
                        .background(BIRGEColors.passengerSurfaceElevated)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(BIRGEColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(BIRGEPressableButtonStyle())
                .disabled(!store.canGoBack)
                .accessibilityIdentifier("passenger_setup_back")

                Spacer()

                Text(headerLabel)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Circle()
                    .fill(BIRGEColors.passengerSurfaceElevated)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(BIRGEColors.borderSubtle, lineWidth: 1))
                    .opacity(0)
                    .accessibilityHidden(true)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(BIRGEColors.brandPrimary.opacity(0.10))
                    Capsule()
                        .fill(BIRGEColors.brandPrimary)
                        .frame(width: max(18, proxy.size.width * progress))
                }
            }
            .frame(height: 7)
            .accessibilityIdentifier("passenger_setup_progress")
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.xs)
        .padding(.bottom, BIRGELayout.xs)
        .background(BIRGEColors.passengerBackground.opacity(0.94))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BIRGEColors.borderSubtle)
                .frame(height: 1)
        }
    }

    private var footer: some View {
        VStack(spacing: BIRGELayout.xs) {
            Button {
                store.send(.continueTapped)
            } label: {
                HStack(spacing: BIRGELayout.xs) {
                    if store.isSaving {
                        ProgressView()
                            .tint(BIRGEColors.textOnBrand)
                    }
                    Text(primaryButtonTitle)
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(store.canContinue ? BIRGEColors.brandPrimary : BIRGEColors.textDisabled)
                .clipShape(Capsule())
            }
            .buttonStyle(BIRGEPressableButtonStyle())
            .disabled(!store.canContinue)
            .accessibilityIdentifier("passenger_setup_continue")
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.xs)
        .padding(.bottom, BIRGELayout.l)
        .background(BIRGEColors.passengerBackground.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BIRGEColors.borderSubtle)
                .frame(height: 1)
        }
    }

    private var headerLabel: String {
        switch store.step {
        case .profileBasics:
            return "Profile"
        case .trustConsent:
            return "Trust"
        case .productIntro:
            return "Step \(store.progressStepIndex) of \(store.progressStepCount)"
        case .firstRouteEntry:
            return "Step \(store.progressStepIndex) of \(store.progressStepCount)"
        }
    }

    private var primaryButtonTitle: String {
        if store.step == .firstRouteEntry, store.routeStep == .review {
            return "Review monthly plans"
        }
        if store.step == .firstRouteEntry {
            switch store.routeStep {
            case .originAddress where store.selectedOriginAddress == nil:
                return "Select an address"
            case .destinationAddress where store.selectedDestinationAddress == nil:
                return "Select a destination"
            case .pickupNode where store.selectedPickupNodeID == nil:
                return "Select pickup node"
            case .dropoffNode where store.selectedDropoffNodeID == nil:
                return "Select dropoff node"
            case .schedule where store.selectedWeekdays.isEmpty || store.departureTime.isEmpty:
                return "Set schedule"
            default:
                break
            }
        }
        return "Continue"
    }

    private var progress: Double {
        Double(store.progressStepIndex) / Double(store.progressStepCount)
    }
}

private struct RouteReviewStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(title: "Review route", subtitle: "Confirm this recurring commute before monthly plans")

            if let draft = store.routeDraftForReview {
                RouteReviewTicket(draft: draft)
                    .accessibilityIdentifier("passenger_route_review_card")
            } else {
                EmptyStateRow(systemImage: "exclamationmark.circle", title: "Route details incomplete")
            }
        }
    }
}

struct SetupHero: View {
    let title: String
    let subtitle: String
    var maxTitleWidth: CGFloat? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: maxTitleWidth, alignment: .leading)
            Text(subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: maxTitleWidth, alignment: .leading)
        }
    }
}

private struct MockupTextRow: View {
    let title: String
    let text: Binding<String>
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .words
    var isAutocorrectionDisabled = false
    let identifier: String
    var isLast = false

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
            Spacer(minLength: BIRGELayout.xs)
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(isAutocorrectionDisabled)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier(identifier)
        }
        .frame(minHeight: 58)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(height: 1)
            }
        }
    }
}

private struct RouteReviewTicket: View {
    let draft: MockRouteDraft

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                Text(draft.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Recurring route")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            HStack(alignment: .top, spacing: BIRGELayout.xs) {
                VStack(spacing: BIRGELayout.xxxs) {
                    Circle()
                        .fill(BIRGEColors.brandPrimary)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(BIRGEColors.passengerSurfaceElevated, lineWidth: 3))
                    Rectangle()
                        .fill(BIRGEColors.brandPrimary.opacity(0.36))
                        .frame(width: 2, height: 54)
                    Circle()
                        .fill(BIRGEColors.textPrimary)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(BIRGEColors.passengerSurfaceElevated, lineWidth: 3))
                }
                VStack(alignment: .leading, spacing: BIRGELayout.s) {
                    ReviewStop(title: "Origin", value: draft.originAddress)
                    ReviewStop(title: "Destination", value: draft.destinationAddress)
                }
            }

            Divider()
                .overlay(BIRGEColors.borderSubtle)

            HStack(spacing: 0) {
                ReviewMetric(title: "Days", value: draft.schedule.weekdays.map { String($0.prefix(2)).uppercased() }.joined(separator: " "))
                ReviewMetric(title: "Window", value: "\(draft.schedule.departureWindowStart)-\(draft.schedule.departureWindowEnd)")
                ReviewMetric(title: "Nodes", value: "2")
            }
        }
        .padding(BIRGELayout.s)
        .background(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .fill(BIRGEColors.passengerSurfaceElevated)
                .shadow(color: BIRGEColors.textPrimary.opacity(0.08), radius: 18, y: 10)
        )
        .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusL).stroke(BIRGEColors.brandPrimary.opacity(0.18), lineWidth: 1))
    }
}

private struct ReviewStop: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ReviewMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BIRGELayout.xxs)
    }
}

struct SelectedValueRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: BIRGELayout.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(BIRGEColors.success)
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
        }
        .padding(BIRGELayout.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BIRGEColors.success.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
    }
}

struct EmptyStateRow: View {
    let systemImage: String
    let title: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(BIRGEColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIRGELayout.s)
            .background(BIRGEColors.passengerSurface)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
            .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).stroke(BIRGEColors.borderSubtle, lineWidth: 1))
    }
}

struct InsightLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: BIRGELayout.xxs) {
            Circle()
                .fill(BIRGEColors.success)
                .frame(width: 7, height: 7)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(BIRGEColors.danger)
            .padding(BIRGELayout.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BIRGEColors.danger.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
    }
}

private struct RowListBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(BIRGEColors.passengerBackground)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(height: 1)
            }
    }
}

#Preview("Profile Basics") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}

#Preview("Trust Consent") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(
            initialStep: .trustConsent,
            fullName: "Passenger",
            city: "Almaty"
        )) {
            OnboardingFeature()
        }
    )
}

#Preview("Product Intro") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(
            initialStep: .productIntro,
            fullName: "Passenger",
            city: "Almaty"
        )) {
            OnboardingFeature()
        }
    )
}

#Preview("Origin Address") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .originAddress,
            originAddressQuery: "Ala",
            originAddressResults: BIRGEProductFixtures.Passenger.addressSearchResults
        )) {
            OnboardingFeature()
        }
    )
}

#Preview("Pickup Node") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .pickupNode,
            selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0],
            suggestedPickupNodes: BIRGEProductFixtures.Passenger.pickupNodes
        )) {
            OnboardingFeature()
        }
    )
}

#Preview("Schedule") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .schedule,
            selectedWeekdays: Set(BIRGEProductFixtures.Passenger.morningSchedule.weekdays),
            departureTime: BIRGEProductFixtures.Passenger.morningSchedule.departureWindowStart,
            flexibilityMinutes: 30
        )) {
            OnboardingFeature()
        }
    )
}

#Preview("Review") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(
            initialStep: .firstRouteEntry,
            routeStep: .review,
            routeDraft: BIRGEProductFixtures.Passenger.draftRoute,
            selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0],
            suggestedPickupNodes: BIRGEProductFixtures.Passenger.pickupNodes,
            selectedPickupNodeID: BIRGEProductFixtures.Passenger.pickupNodes[0].id,
            selectedDestinationAddress: BIRGEProductFixtures.Passenger.addressSearchResults[1],
            suggestedDropoffNodes: BIRGEProductFixtures.Passenger.dropoffNodes,
            selectedDropoffNodeID: BIRGEProductFixtures.Passenger.dropoffNodes[0].id,
            selectedWeekdays: Set(BIRGEProductFixtures.Passenger.morningSchedule.weekdays),
            departureTime: BIRGEProductFixtures.Passenger.morningSchedule.departureWindowStart
        )) {
            OnboardingFeature()
        }
    )
}
