//
//  OTPPhoneView.swift
//  BIRGEPassenger
//
//  Matches P-01-phone.html:
//  setup-screen layout — nav header (back + "Вход"), hero, +7 phone field,
//  helper text, footer primary CTA.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

struct OTPPhoneView: View {
    @Bindable var store: StoreOf<OTPFeature>

    var body: some View {
        VStack(spacing: 0) {
            // Nav header
            OTPNavHeader(stepLabel: "Вход")

            // Scrollable body
            ScrollView {
                VStack(alignment: .leading, spacing: BIRGELayout.xl) {
                    // Hero
                    VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                        Text("Войти по номеру")
                            .font(.system(.largeTitle, design: .default, weight: .bold))
                            .foregroundStyle(BIRGEColors.textPrimary)

                        Text("Код придёт в SMS")
                            .font(BIRGEFonts.subtext)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }

                    // Phone field
                    VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                        HStack(spacing: 0) {
                            // +7 prefix badge
                            Text("+7")
                                .font(BIRGEFonts.sectionTitle)
                                .foregroundStyle(BIRGEColors.textPrimary)
                                .padding(.horizontal, BIRGELayout.s)
                                .frame(height: 54)
                                .background(BIRGEColors.passengerSurfaceSubtle)
                                .overlay(
                                    Rectangle()
                                        .fill(BIRGEColors.borderSubtle)
                                        .frame(width: 1),
                                    alignment: .trailing
                                )

                            // Number input
                            TextField("700 123 45 67", text: phoneBinding)
                                .keyboardType(.phonePad)
                                .font(BIRGEFonts.sectionTitle)
                                .foregroundStyle(BIRGEColors.textPrimary)
                                .tint(BIRGEColors.brandPrimary)
                                .padding(.horizontal, BIRGELayout.s)
                                .frame(height: 54)
                                .frame(maxWidth: .infinity)
                                .accessibilityLabel("Номер телефона")
                                .accessibilityIdentifier("otp_phone_field")
                        }
                        .background(BIRGEColors.passengerSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
                        .overlay(
                            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                                .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
                        )

                        // Helper
                        Text("Номер нужен для профиля и поддержки.")
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textTertiary)
                    }
                }
                .padding(.horizontal, BIRGELayout.m)
                .padding(.top, BIRGELayout.l)
            }

            Spacer(minLength: 0)

            // Footer CTA
            VStack(spacing: 0) {
                Divider()
                    .background(BIRGEColors.borderSubtle)

                BIRGEPrimaryButton(
                    title: "Получить код",
                    isLoading: store.isLoading
                ) {
                    store.send(.sendOTPTapped)
                }
                .disabled(store.phoneNumber.count < 10 || store.isLoading)
                .opacity(store.phoneNumber.count >= 10 ? 1 : 0.45)
                .padding(.horizontal, BIRGELayout.m)
                .padding(.vertical, BIRGELayout.s)
                .accessibilityIdentifier("otp_send_code_button")
            }
        }
        .background(BIRGEColors.passengerBackground.ignoresSafeArea())
    }

    // MARK: - Binding

    private var phoneBinding: Binding<String> {
        Binding(
            get: { store.phoneNumber },
            set: { store.send(.phoneChanged($0)) }
        )
    }
}

// MARK: - Preview

#Preview("Phone entry") {
    OTPPhoneView(
        store: Store(initialState: OTPFeature.State(step: .phone)) {
            OTPFeature()
        }
    )
}
