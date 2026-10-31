import BIRGECore
import ComposableArchitecture
import SwiftUI

struct ProfileBasicsStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(
                title: "Коротко о вас",
                subtitle: "Для профиля и уведомлений"
            )

            VStack(spacing: 0) {
                ProfileBasicsTextRow(
                    title: "Имя",
                    placeholder: "Данияр",
                    text: Binding(
                        get: { store.fullName },
                        set: { store.send(.fullNameChanged($0)) }
                    )
                )
                .accessibilityIdentifier("passenger_profile_full_name")

                ProfileBasicsTextRow(
                    title: "Город",
                    placeholder: "Алматы",
                    text: Binding(
                        get: { store.city },
                        set: { store.send(.cityChanged($0)) }
                    )
                )
                .accessibilityIdentifier("passenger_profile_city")

                ProfileBasicsTextRow(
                    title: "Email",
                    placeholder: "необязательно",
                    text: Binding(
                        get: { store.email },
                        set: { store.send(.emailChanged($0)) }
                    ),
                    isLast: true
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .accessibilityIdentifier("passenger_profile_email")
            }
            .padding(.top, BIRGELayout.xs)
            .overlay(alignment: .top) { profileDivider }
            .overlay(alignment: .bottom) { profileDivider }

            Text("Точные адреса не показываются другим пассажирам.")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, BIRGELayout.xxs)
        }
    }

    private var profileDivider: some View {
        Rectangle()
            .fill(BIRGEColors.borderSubtle)
            .frame(height: 1)
    }
}

private struct ProfileBasicsTextRow: View {
    let title: String
    let placeholder: String
    let text: Binding<String>
    var isLast = false

    var body: some View {
        HStack(spacing: BIRGELayout.s) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)

            Spacer(minLength: BIRGELayout.xs)

            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.words)
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

#Preview("Profile Basics Step") {
    ProfileBasicsStepView(
        store: Store(initialState: OnboardingFeature.State(
            fullName: "Aruzhan",
            city: "Almaty",
            email: "aruzhan@example.com"
        )) {
            OnboardingFeature()
        }
    )
    .padding(BIRGELayout.m)
    .background(BIRGEColors.passengerBackground)
}
