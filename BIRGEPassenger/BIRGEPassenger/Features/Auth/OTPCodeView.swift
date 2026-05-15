//
//  OTPCodeView.swift
//  BIRGEPassenger
//
//  Matches P-02-otp.html:
//  setup-screen layout — nav header (back + "SMS"), hero, 6 OTP cells,
//  inline resend countdown + "Изменить номер" link, footer primary CTA.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

struct OTPCodeView: View {
    @Bindable var store: StoreOf<OTPFeature>

    @FocusState private var isCodeFieldFocused: Bool
    @State private var resendSecondsRemaining = 60
    @State private var resendTimerTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Nav header — back returns to phone step
            OTPNavHeader(stepLabel: "SMS") {
                store.send(.changePhoneTapped)
            }

            // Scrollable body
            ScrollView {
                VStack(alignment: .leading, spacing: BIRGELayout.xl) {
                    // Hero
                    VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                        Text("Введите код")
                            .font(.system(.largeTitle, design: .default, weight: .bold))
                            .foregroundStyle(BIRGEColors.textPrimary)

                        Text("Отправили на +7 \(store.phoneNumber)")
                            .font(BIRGEFonts.subtext)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }

                    // OTP boxes + inline actions
                    VStack(alignment: .leading, spacing: BIRGELayout.s) {
                        otpBoxes

                        // Inline actions row: resend countdown | change number
                        HStack {
                            resendControl
                            Spacer()
                            Button("Изменить номер") {
                                store.send(.changePhoneTapped)
                            }
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.brandPrimary)
                            .birgeTapTarget()
                            .accessibilityIdentifier("otp_change_number_button")
                        }
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
                    title: "Продолжить",
                    isLoading: store.isLoading
                ) {
                    store.send(.verifyTapped)
                }
                .disabled(store.otpCode.count != 6 || store.isLoading)
                .opacity(store.otpCode.count == 6 ? 1 : 0.45)
                .padding(.horizontal, BIRGELayout.m)
                .padding(.vertical, BIRGELayout.s)
                .accessibilityIdentifier("otp_verify_button")
            }
        }
        .background(BIRGEColors.passengerBackground.ignoresSafeArea())
        .onAppear {
            isCodeFieldFocused = true
            startResendTimer()
        }
        .onDisappear {
            resendTimerTask?.cancel()
        }
    }

    // MARK: - OTP Boxes

    private var otpBoxes: some View {
        ZStack {
            // Hidden text field captures keyboard input
            TextField("", text: codeBinding)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFieldFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)

            HStack(spacing: BIRGELayout.xxs) {
                ForEach(0..<6, id: \.self) { index in
                    otpCell(at: index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isCodeFieldFocused = true }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Код подтверждения: \(store.otpCode)")
            .accessibilityIdentifier("otp_code_boxes")
        }
    }

    private func otpCell(at index: Int) -> some View {
        let characters = Array(store.otpCode.prefix(6))
        let hasError = store.errorMessage != nil
        let isFocused = isCodeFieldFocused && index == min(store.otpCode.count, 5)
        let value = index < characters.count ? String(characters[index]) : ""

        let borderColor: Color = {
            if hasError { return BIRGEColors.danger }
            if isFocused { return BIRGEColors.brandPrimary }
            return BIRGEColors.borderSubtle
        }()
        let borderWidth: CGFloat = (hasError || isFocused) ? 2 : 1

        return Text(value)
            .font(BIRGEFonts.otpDigit)
            .foregroundStyle(BIRGEColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                    .fill(hasError
                          ? BIRGEColors.danger.opacity(0.08)
                          : BIRGEColors.passengerSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    // MARK: - Resend Control

    @ViewBuilder
    private var resendControl: some View {
        if resendSecondsRemaining > 0 {
            Text("Повторно через 0:\(String(format: "%02d", resendSecondsRemaining))")
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textTertiary)
        } else {
            Button("Отправить повторно") {
                store.send(.sendOTPTapped)
                startResendTimer()
            }
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(BIRGEColors.brandPrimary)
            .birgeTapTarget()
            .accessibilityIdentifier("otp_resend_button")
        }
    }

    // MARK: - Timer

    private func startResendTimer() {
        resendTimerTask?.cancel()
        resendSecondsRemaining = 60
        resendTimerTask = Task { @MainActor in
            while resendSecondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                resendSecondsRemaining -= 1
            }
        }
    }

    // MARK: - Binding

    private var codeBinding: Binding<String> {
        Binding(
            get: { store.otpCode },
            set: { store.send(.otpChanged(String($0.filter(\.isNumber).prefix(6)))) }
        )
    }
}

// MARK: - Preview

#Preview("Code entry — empty") {
    OTPCodeView(
        store: Store(initialState: OTPFeature.State(
            phoneNumber: "7001234567",
            step: .code
        )) {
            OTPFeature()
        }
    )
}

#Preview("Code entry — partial") {
    OTPCodeView(
        store: Store(initialState: OTPFeature.State(
            phoneNumber: "7001234567",
            otpCode: "481",
            step: .code
        )) {
            OTPFeature()
        }
    )
}

#Preview("Code entry — error") {
    OTPCodeView(
        store: Store(initialState: OTPFeature.State(
            phoneNumber: "7001234567",
            otpCode: "481000",
            step: .code,
            errorMessage: "Неверный код. Попробуйте ещё раз."
        )) {
            OTPFeature()
        }
    )
}
