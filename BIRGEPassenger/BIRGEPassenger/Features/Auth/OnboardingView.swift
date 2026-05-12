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

private struct ProfileBasicsStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(title: "A little about you", subtitle: "For your profile and route updates")

            VStack(spacing: 0) {
                MockupTextRow(
                    title: "Name",
                    text: Binding(get: { store.fullName }, set: { store.send(.fullNameChanged($0)) }),
                    placeholder: "Your name",
                    identifier: "passenger_profile_full_name"
                )
                MockupTextRow(
                    title: "City",
                    text: Binding(get: { store.city }, set: { store.send(.cityChanged($0)) }),
                    placeholder: "Almaty",
                    identifier: "passenger_profile_city"
                )
                MockupTextRow(
                    title: "Email",
                    text: Binding(get: { store.email }, set: { store.send(.emailChanged($0)) }),
                    placeholder: "Optional",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never,
                    isAutocorrectionDisabled: true,
                    identifier: "passenger_profile_email",
                    isLast: true
                )
            }
            .background(RowListBackground())

            Text("Exact addresses are not shown to other passengers.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct TrustConsentStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(title: "Trust and consent", subtitle: "Choose what BIRGE can use for your commute")

            VStack(spacing: 0) {
                ConsentRailRow(
                    title: "Notifications",
                    subtitle: "Pickup reminders and schedule changes",
                    systemImage: "bell",
                    isOn: Binding(get: { store.notificationsConsent }, set: { if $0 != store.notificationsConsent { store.send(.notificationsConsentToggled) } }),
                    identifier: "passenger_consent_notifications"
                )
                ConsentRailRow(
                    title: "Location",
                    subtitle: "Suggested pickup and dropoff nodes",
                    systemImage: "location.circle",
                    isOn: Binding(get: { store.locationConsent }, set: { if $0 != store.locationConsent { store.send(.locationConsentToggled) } }),
                    identifier: "passenger_consent_location"
                )
                ConsentRailRow(
                    title: "Route privacy",
                    subtitle: "Share only what matching needs",
                    systemImage: "lock.shield",
                    isOn: Binding(get: { store.routePrivacyConsent }, set: { if $0 != store.routePrivacyConsent { store.send(.routePrivacyConsentToggled) } }),
                    identifier: "passenger_consent_route_privacy",
                    isLast: true
                )
            }
            .background(RowListBackground())

            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 36, height: 36)
                    .background(BIRGEColors.brandPrimary.opacity(0.10))
                    .clipShape(Circle())
                Text("Route details stay limited to your commute coordination.")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ProductIntroStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.l) {
            SetupHero(
                title: "Build your commute",
                subtitle: "Start with addresses, then choose pickup and dropoff nodes.",
                maxTitleWidth: 270
            )

            RouteIntroCanvas()

            IntroStepper()
                .padding(.top, BIRGELayout.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RouteOriginStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(title: "Where do you start?", subtitle: "Enter an address before choosing a nearby node")
            AddressSearchPanel(
                mode: .origin,
                label: "Home, building, or street",
                text: Binding(get: { store.originAddressQuery }, set: { store.send(.originQueryChanged($0)) }),
                results: store.originAddressResults,
                selectedAddress: store.selectedOriginAddress,
                isLoading: store.isLoadingRouteData,
                resultIdentifierPrefix: "passenger_origin_result"
            ) { result in
                store.send(.originAddressSelected(result))
            }
            .accessibilityIdentifier("passenger_route_origin")
        }
    }
}

private struct PickupNodeStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        NodePickerStepView(
            title: "Choose pickup node",
            subtitle: "Suggested points near your selected address",
            areaTitle: store.selectedOriginAddress?.title,
            nodes: store.suggestedPickupNodes,
            selectedID: store.selectedPickupNodeID,
            emptyTitle: "Select an origin address first",
            identifierPrefix: "passenger_pickup_node"
        ) { id in
            store.send(.pickupNodeSelected(id))
        }
    }
}

private struct RouteDestinationStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(title: "Where are you going?", subtitle: "Search the destination before choosing dropoff")
            AddressSearchPanel(
                mode: .destination,
                label: "Work, campus, or destination",
                text: Binding(get: { store.destinationAddressQuery }, set: { store.send(.destinationQueryChanged($0)) }),
                results: store.destinationAddressResults,
                selectedAddress: store.selectedDestinationAddress,
                isLoading: store.isLoadingRouteData,
                resultIdentifierPrefix: "passenger_destination_result"
            ) { result in
                store.send(.destinationAddressSelected(result))
            }
            .accessibilityIdentifier("passenger_route_destination")
        }
    }
}

private struct DropoffNodeStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        NodePickerStepView(
            title: "Choose dropoff node",
            subtitle: "Suggested points near your destination",
            areaTitle: store.selectedDestinationAddress?.title,
            nodes: store.suggestedDropoffNodes,
            selectedID: store.selectedDropoffNodeID,
            emptyTitle: "Select a destination address first",
            identifierPrefix: "passenger_dropoff_node"
        ) { id in
            store.send(.dropoffNodeSelected(id))
        }
    }
}

private struct RouteScheduleStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(title: "Schedule", subtitle: "When do you usually commute?")

            HStack(spacing: BIRGELayout.xxs) {
                ForEach(store.availableWeekdays, id: \.self) { weekday in
                    Button {
                        store.send(.weekdayToggled(weekday))
                    } label: {
                        Text(weekdayDisplayName(weekday))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(store.selectedWeekdays.contains(weekday) ? BIRGEColors.textOnBrand : BIRGEColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(store.selectedWeekdays.contains(weekday) ? BIRGEColors.brandPrimary : BIRGEColors.passengerSurface)
                            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
                            .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusS).stroke(BIRGEColors.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(BIRGEPressableButtonStyle())
                    .accessibilityIdentifier("passenger_schedule_day_\(weekday)")
                }
            }

            VStack(spacing: BIRGELayout.s) {
                HStack {
                    Text("Departure time")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BIRGEColors.textSecondary)
                    Spacer()
                    Text(store.departureTime.isEmpty ? "Set time" : store.departureTime)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(BIRGEColors.textPrimary)
                }

                NativeTimeWheelPicker(
                    hour: hourBinding,
                    minute: minuteBinding
                )
                .accessibilityIdentifier("passenger_schedule_departure_time")

                VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                    HStack {
                        Text("Flexibility")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BIRGEColors.textSecondary)
                        Spacer()
                        Text("Window: \(windowText)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(BIRGEColors.textPrimary)
                    }

                    HStack(spacing: BIRGELayout.xxs) {
                        ForEach([15, 30, 45], id: \.self) { value in
                            Button {
                                store.send(.flexibilityMinutesChanged(value))
                            } label: {
                                Text("±\(value) min")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(store.flexibilityMinutes == value ? BIRGEColors.textPrimary : BIRGEColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(store.flexibilityMinutes == value ? BIRGEColors.passengerSurfaceElevated : BIRGEColors.passengerSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
                            }
                            .buttonStyle(BIRGEPressableButtonStyle())
                        }
                    }
                }
                .padding(BIRGELayout.s)
                .background(BIRGEColors.passengerSurface)
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
                .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusL).stroke(BIRGEColors.borderSubtle, lineWidth: 1))
            }

            InsightLine(text: "A wider window helps match the commute.")
        }
    }

    private var hourBinding: Binding<Int> {
        Binding(
            get: { hourValue },
            set: { store.send(.departureHourChanged($0)) }
        )
    }

    private var minuteBinding: Binding<Int> {
        Binding(
            get: { minuteValue },
            set: { store.send(.departureMinuteChanged($0)) }
        )
    }

    private var hourValue: Int {
        let parts = store.departureTime.split(separator: ":").compactMap { Int($0) }
        return parts.first.map { max(0, min(23, $0)) } ?? 7
    }

    private var minuteValue: Int {
        let parts = store.departureTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count > 1 else { return 45 }
        let minute = max(0, min(59, parts[1]))
        return (minute / 5) * 5
    }

    private var windowText: String {
        guard !store.departureTime.isEmpty else { return "Set time" }
        return "\(store.departureTime)-\(store.departureWindowEnd)"
    }

    private func weekdayDisplayName(_ weekday: String) -> String {
        String(weekday.prefix(2)).uppercased()
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

private struct SetupHero: View {
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

private struct ConsentRailRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isOn: Binding<Bool>
    let identifier: String
    var isLast = false

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer(minLength: BIRGELayout.xs)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(BIRGEColors.brandPrimary)
        }
        .frame(minHeight: 62)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(height: 1)
            }
        }
        .accessibilityIdentifier(identifier)
    }
}

private struct IntroStepper: View {
    private let steps = [
        "Addresses",
        "Pickup and dropoff nodes",
        "Schedule"
    ]

    var body: some View {
        HStack(alignment: .top, spacing: BIRGELayout.xs) {
            ZStack(alignment: .top) {
                Capsule()
                    .fill(BIRGEColors.brandPrimary.opacity(0.22))
                    .frame(width: 2)
                    .padding(.vertical, 17)

                VStack(spacing: BIRGELayout.l) {
                    ForEach(steps.indices, id: \.self) { index in
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(index == 0 ? BIRGEColors.textOnBrand : BIRGEColors.brandPrimary)
                            .frame(width: 34, height: 34)
                            .background(index == 0 ? BIRGEColors.brandPrimary : BIRGEColors.brandPrimary.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(BIRGEColors.passengerBackground, lineWidth: 3))
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(width: 34)

            VStack(alignment: .leading, spacing: BIRGELayout.l) {
                ForEach(steps, id: \.self) { title in
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(BIRGEColors.textPrimary)
                        .frame(height: 34, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, BIRGELayout.m)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private enum AddressSearchMode {
    case origin
    case destination
}

private struct AddressSearchPanel: View {
    let mode: AddressSearchMode
    let label: String
    let text: Binding<String>
    let results: [MockAddressSearchResult]
    let selectedAddress: MockAddressSearchResult?
    let isLoading: Bool
    let resultIdentifierPrefix: String
    let onSelect: (MockAddressSearchResult) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            RouteAddressCanvas(
                mode: mode,
                origin: mode == .origin ? selectedAddress?.title ?? text.wrappedValue : nil,
                destination: mode == .destination ? selectedAddress?.title ?? text.wrappedValue : nil
            )

            VStack(spacing: 0) {
                MockupTextRow(
                    title: label,
                    text: text,
                    placeholder: "Search",
                    identifier: "\(resultIdentifierPrefix)_field",
                    isLast: true
                )
            }
            .background(RowListBackground())

            if isLoading {
                ProgressView()
                    .tint(BIRGEColors.brandPrimary)
                    .accessibilityIdentifier("\(resultIdentifierPrefix)_loading")
            }

            if let selectedAddress {
                SelectedValueRow(title: selectedAddress.title, subtitle: selectedAddress.fullAddress)
                    .accessibilityIdentifier("\(resultIdentifierPrefix)_selected")
            } else if !text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                InsightLine(text: "Choose a suggestion to continue.")
                    .accessibilityIdentifier("\(resultIdentifierPrefix)_select_hint")
            }

            VStack(spacing: BIRGELayout.xs) {
                ForEach(results) { result in
                    Button {
                        onSelect(result)
                    } label: {
                        AddressResultRow(result: result)
                    }
                    .buttonStyle(BIRGEPressableButtonStyle())
                    .accessibilityIdentifier("\(resultIdentifierPrefix)_\(result.id.uuidString)")
                }
            }
        }
    }
}

private struct NodePickerStepView: View {
    let title: String
    let subtitle: String
    let areaTitle: String?
    let nodes: [MockCommuteNode]
    let selectedID: MockCommuteNode.ID?
    let emptyTitle: String
    let identifierPrefix: String
    let onSelect: (MockCommuteNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(title: title, subtitle: subtitle)

            NodeCanvas(areaTitle: areaTitle, nodes: nodes, selectedID: selectedID)

            Text("Nearest nodes")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)

            if nodes.isEmpty {
                EmptyStateRow(systemImage: "mappin.slash", title: emptyTitle)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                        Button {
                            onSelect(node.id)
                        } label: {
                            NodeRow(node: node, isSelected: selectedID == node.id, isLast: index == nodes.count - 1)
                        }
                        .buttonStyle(BIRGEPressableButtonStyle())
                        .accessibilityIdentifier("\(identifierPrefix)_\(node.id.uuidString)")
                    }
                }
                .background(RowListBackground())
            }

            InsightLine(text: "Exact addresses stay private from other passengers.")
        }
    }
}

private struct RouteAddressCanvas: View {
    let mode: AddressSearchMode
    let origin: String?
    let destination: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(BIRGEColors.routeCanvasBackground)
            CanvasGrid()
            RouteLine()
                .stroke(BIRGEColors.brandPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(height: 100)
                .rotationEffect(.degrees(-8))
                .shadow(color: BIRGEColors.brandPrimary.opacity(0.20), radius: 8)

            AddressBubble(
                title: "Start",
                value: originValue,
                isBrand: mode == .origin
            )
                .frame(maxWidth: 132)
                .position(x: 78, y: 66)

            AddressBubble(
                title: "Work",
                value: destinationValue,
                isBrand: mode == .destination
            )
                .frame(maxWidth: 132)
                .position(x: 262, y: 152)
        }
        .frame(height: 218)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: BIRGEColors.textPrimary.opacity(0.08), radius: 18, y: 10)
    }

    private var originValue: String {
        let value = origin?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "Address" : value
    }

    private var destinationValue: String {
        let value = destination?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "Destination" : value
    }
}

private struct NodeCanvas: View {
    let areaTitle: String?
    let nodes: [MockCommuteNode]
    let selectedID: MockCommuteNode.ID?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(BIRGEColors.routeCanvasBackground)
            CanvasGrid()

            Text(areaTitle ?? "Selected area")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .padding(.horizontal, BIRGELayout.xs)
                .padding(.vertical, BIRGELayout.xxs)
                .background(BIRGEColors.passengerSurfaceElevated)
                .clipShape(Capsule())
                .position(x: 100, y: 48)

            ForEach(Array(nodes.prefix(3).enumerated()), id: \.element.id) { index, node in
                NodePin(title: node.title, isSelected: selectedID == node.id)
                    .position(pinPosition(index))
            }
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: BIRGEColors.textPrimary.opacity(0.08), radius: 18, y: 10)
    }

    private func pinPosition(_ index: Int) -> CGPoint {
        switch index {
        case 0:
            return CGPoint(x: 88, y: 112)
        case 1:
            return CGPoint(x: 224, y: 90)
        default:
            return CGPoint(x: 186, y: 168)
        }
    }
}

private struct RouteIntroCanvas: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(BIRGEColors.routeCanvasBackground)
            CanvasGrid()
            RouteLine()
                .stroke(BIRGEColors.brandPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-8))
                .shadow(color: BIRGEColors.brandPrimary.opacity(0.18), radius: 8)
                .padding(.horizontal, 48)
            Circle()
                .fill(BIRGEColors.brandPrimary)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(BIRGEColors.passengerSurfaceElevated, lineWidth: 4))
                .position(x: 54, y: 88)
            Circle()
                .fill(BIRGEColors.brandPrimary)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(BIRGEColors.passengerSurfaceElevated, lineWidth: 4))
                .position(x: 292, y: 58)
            Circle()
                .fill(BIRGEColors.brandPrimary.opacity(0.42))
                .frame(width: 9, height: 9)
                .position(x: 132, y: 80)
            Circle()
                .fill(BIRGEColors.brandPrimary.opacity(0.42))
                .frame(width: 9, height: 9)
                .position(x: 228, y: 70)
        }
        .frame(height: 146)
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

private struct CanvasGrid: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.055))
                    .frame(height: 1)
                    .offset(y: CGFloat(index * 28) - 98)
                Rectangle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.055))
                    .frame(width: 1)
                    .offset(x: CGFloat(index * 42) - 140)
            }
        }
    }
}

private struct RouteLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 20, y: rect.midY + 12))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 20, y: rect.midY - 10),
            control1: CGPoint(x: rect.midX - 70, y: rect.midY - 20),
            control2: CGPoint(x: rect.midX + 48, y: rect.midY + 22)
        )
        return path
    }
}

private struct AddressBubble: View {
    let title: String
    let value: String
    let isBrand: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isBrand ? BIRGEColors.brandPrimary : BIRGEColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, BIRGELayout.xs)
        .padding(.vertical, BIRGELayout.xs)
        .background(BIRGEColors.passengerSurfaceElevated.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).stroke(BIRGEColors.borderSubtle, lineWidth: 1))
        .shadow(color: BIRGEColors.textPrimary.opacity(0.08), radius: 10, y: 6)
    }
}

private struct NodePin: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: BIRGELayout.xxxs) {
            ZStack {
                Circle()
                    .fill(isSelected ? BIRGEColors.brandPrimary : BIRGEColors.passengerSurfaceElevated)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(isSelected ? BIRGEColors.textOnBrand : BIRGEColors.brandPrimary, lineWidth: 4))
                if isSelected {
                    Circle()
                        .fill(BIRGEColors.textOnBrand)
                        .frame(width: 6, height: 6)
                }
            }
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 84)
                .padding(.horizontal, BIRGELayout.xxxs)
                .padding(.vertical, 3)
                .background(BIRGEColors.passengerSurfaceElevated.opacity(0.90))
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusXS))
        }
    }
}

private struct AddressResultRow: View {
    let result: MockAddressSearchResult

    var body: some View {
        HStack(alignment: .top, spacing: BIRGELayout.xs) {
            Image(systemName: "mappin.circle")
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 30, height: 30)
                .background(BIRGEColors.brandPrimary.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(result.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(result.subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                Text(result.fullAddress)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BIRGEColors.textTertiary)
            }

            Spacer(minLength: BIRGELayout.xs)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.textTertiary)
        }
        .padding(BIRGELayout.s)
        .background(BIRGEColors.passengerSurface)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).stroke(BIRGEColors.borderSubtle, lineWidth: 1))
    }
}

private struct NodeRow: View {
    let node: MockCommuteNode
    let isSelected: Bool
    var isLast = false

    var body: some View {
        HStack(alignment: .center, spacing: BIRGELayout.xs) {
            Circle()
                .fill(BIRGEColors.brandPrimary)
                .frame(width: 13, height: 13)

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(node.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("\(node.subtitle) · \(node.walkingMinutes) min walk")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: BIRGELayout.xs)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(isSelected ? BIRGEColors.brandPrimary : BIRGEColors.borderSubtle)
        }
        .frame(minHeight: 64)
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

private struct NativeTimeWheelPicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .fill(BIRGEColors.brandPrimary.opacity(0.07))
                .frame(height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                        .stroke(BIRGEColors.brandPrimary.opacity(0.12), lineWidth: 1)
                )

            HStack(spacing: 2) {
                Picker("Hour", selection: $hour) {
                    ForEach(0..<24, id: \.self) { value in
                        Text(String(format: "%02d", value))
                            .font(.system(size: 30, weight: .bold, design: .default))
                            .foregroundStyle(value == hour ? BIRGEColors.textPrimary : BIRGEColors.textTertiary)
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(width: 96, height: 136)
                .clipped()

                Text(":")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .frame(width: 16, height: 42)

                Picker("Minute", selection: $minute) {
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { value in
                        Text(String(format: "%02d", value))
                            .font(.system(size: 30, weight: .bold, design: .default))
                            .foregroundStyle(value == minute ? BIRGEColors.textPrimary : BIRGEColors.textTertiary)
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(width: 96, height: 136)
                .clipped()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 136)
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
        .mask(
            LinearGradient(
                stops: [
                    .init(color: BIRGEColors.textPrimary.opacity(0), location: 0),
                    .init(color: BIRGEColors.textPrimary.opacity(1), location: 0.22),
                    .init(color: BIRGEColors.textPrimary.opacity(1), location: 0.78),
                    .init(color: BIRGEColors.textPrimary.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct SelectedValueRow: View {
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

private struct EmptyStateRow: View {
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

private struct InsightLine: View {
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
