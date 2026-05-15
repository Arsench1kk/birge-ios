import BIRGECore
import ComposableArchitecture
import SwiftUI

struct ProfileBasicsStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            BIRGESectionHeader(
                title: "A little about you",
                subtitle: "For your profile and route updates"
            )

            VStack(spacing: BIRGELayout.s) {
                BIRGETextFieldRow(
                    title: "Name",
                    placeholder: "Your name",
                    text: Binding(
                        get: { store.fullName },
                        set: { store.send(.fullNameChanged($0)) }
                    )
                )
                .accessibilityIdentifier("passenger_profile_full_name")

                BIRGETextFieldRow(
                    title: "City",
                    placeholder: "Almaty",
                    text: Binding(
                        get: { store.city },
                        set: { store.send(.cityChanged($0)) }
                    )
                )
                .accessibilityIdentifier("passenger_profile_city")

                BIRGETextFieldRow(
                    title: "Email",
                    placeholder: "Optional",
                    text: Binding(
                        get: { store.email },
                        set: { store.send(.emailChanged($0)) }
                    )
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .accessibilityIdentifier("passenger_profile_email")
            }

            Text("Exact addresses are not shown to other passengers.")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
