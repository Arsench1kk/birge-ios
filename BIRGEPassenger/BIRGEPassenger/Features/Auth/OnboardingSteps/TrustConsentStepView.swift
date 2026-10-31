import BIRGECore
import ComposableArchitecture
import SwiftUI
struct TrustConsentStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(
                title: "Разрешения",
                subtitle: "Для поездок по расписанию"
            )
            VStack(spacing: 0) {
                TrustConsentToggleRow(
                    title: "Уведомления",
                    subtitle: "статусы поездок",
                    systemImage: "bell.badge",
                    isOn: store.notificationsConsent,
                    identifier: "passenger_consent_notifications"
                ) { store.send(.notificationsConsentToggled) }
                TrustConsentToggleRow(
                    title: "Локация",
                    subtitle: "точка посадки",
                    systemImage: "location.fill",
                    isOn: store.locationConsent,
                    identifier: "passenger_consent_location"
                ) { store.send(.locationConsentToggled) }
                TrustConsentToggleRow(
                    title: "Приватность маршрутов",
                    subtitle: "адрес скрыт",
                    systemImage: "lock.shield.fill",
                    isOn: store.routePrivacyConsent,
                    identifier: "passenger_consent_route_privacy",
                    isLast: true
                ) { store.send(.routePrivacyConsentToggled) }
            }
            .padding(.top, BIRGELayout.xxxs)
            .overlay(alignment: .top) { divider }
            .overlay(alignment: .bottom) { divider }
            Label {
                Text("Точный адрес скрыт")
                    .font(.system(size: 14, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 36, height: 36)
                    .background(BIRGEColors.brandPrimary.opacity(0.10))
                    .clipShape(Circle())
            }
            .foregroundStyle(BIRGEColors.textPrimary)
        }
    }
    private var divider: some View {
        Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
    }
}
private struct TrustConsentToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isOn: Bool
    let identifier: String
    var isLast = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BIRGELayout.s) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: BIRGELayout.xs)

                TrustConsentSwitchIndicator(isOn: isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(BIRGEPressableButtonStyle())
        .frame(minHeight: 62)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(height: 1)
            }
        }
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

private struct TrustConsentSwitchIndicator: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? BIRGEColors.brandPrimary.opacity(0.16) : BIRGEColors.borderSubtle.opacity(0.75))
            .frame(width: 28, height: 17)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(isOn ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary.opacity(0.65))
                    .frame(width: 13, height: 13)
                    .padding(2)
            }
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
