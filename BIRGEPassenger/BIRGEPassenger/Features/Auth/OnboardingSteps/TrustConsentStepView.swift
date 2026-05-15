import BIRGECore
import ComposableArchitecture
import SwiftUI
struct TrustConsentStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            BIRGESectionHeader(
                title: "Trust and consent",
                subtitle: "Choose what BIRGE can use for your commute"
            )
            VStack(spacing: 0) {
                TrustConsentToggleRow(
                    title: "Notifications",
                    subtitle: "Pickup reminders and schedule changes",
                    systemImage: "bell.badge",
                    isOn: notificationsBinding,
                    identifier: "passenger_consent_notifications"
                )
                TrustConsentToggleRow(
                    title: "Location",
                    subtitle: "Suggested pickup and dropoff nodes",
                    systemImage: "location.fill",
                    isOn: locationBinding,
                    identifier: "passenger_consent_location"
                )
                TrustConsentToggleRow(
                    title: "Route privacy",
                    subtitle: "Share only what matching needs",
                    systemImage: "lock.shield.fill",
                    isOn: routePrivacyBinding,
                    identifier: "passenger_consent_route_privacy",
                    isLast: true
                )
            }
            .background(BIRGEColors.passengerBackground)
            .overlay(alignment: .top) { divider }
            .overlay(alignment: .bottom) { divider }
            Label {
                Text("Route details stay limited to your commute coordination.")
                    .font(BIRGEFonts.captionBold)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .font(BIRGEFonts.bodyMedium)
            }
            .foregroundStyle(BIRGEColors.textPrimary)
        }
    }
    private var notificationsBinding: Binding<Bool> {
        Binding(get: { store.notificationsConsent }, set: { if $0 != store.notificationsConsent { store.send(.notificationsConsentToggled) } })
    }
    private var locationBinding: Binding<Bool> {
        Binding(get: { store.locationConsent }, set: { if $0 != store.locationConsent { store.send(.locationConsentToggled) } })
    }
    private var routePrivacyBinding: Binding<Bool> {
        Binding(get: { store.routePrivacyConsent }, set: { if $0 != store.routePrivacyConsent { store.send(.routePrivacyConsentToggled) } })
    }
    private var divider: some View {
        Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
    }
}
private struct TrustConsentToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isOn: Binding<Bool>
    let identifier: String
    var isLast = false
    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: systemImage)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(title)
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(subtitle)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: BIRGELayout.xs)
            Toggle(title, isOn: isOn)
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
#Preview("Trust Consent Step") {
    TrustConsentStepView(
        store: Store(initialState: OnboardingFeature.State(initialStep: .trustConsent, fullName: "Aruzhan", city: "Almaty", notificationsConsent: true, locationConsent: true)) {
            OnboardingFeature()
        }
    )
    .padding(BIRGELayout.m)
    .background(BIRGEColors.passengerBackground)
}
