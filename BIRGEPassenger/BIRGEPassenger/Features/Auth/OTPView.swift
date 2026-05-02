//
//  OTPView.swift
//  BIRGEPassenger
//

import ComposableArchitecture
import SwiftUI

struct OTPView: View {
    @Bindable var store: StoreOf<OTPFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isCodeFieldFocused: Bool
    @State private var resendSecondsRemaining = 60
    @State private var resendTimerTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            BIRGEColors.brandPrimary
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo / Brand
                brandHeader

                Spacer().frame(height: BIRGELayout.xxxl)

                // Content card
                VStack(spacing: BIRGELayout.l) {
                    switch store.step {
                    case .phone:
                        phoneInputSection
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .leading)
                                        .combined(with: .opacity),
                                    removal: .move(edge: .leading)
                                        .combined(with: .opacity)
                                )
                            )

                    case .code:
                        codeInputSection
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing)
                                        .combined(with: .opacity),
                                    removal: .move(edge: .trailing)
                                        .combined(with: .opacity)
                                )
                            )
                    }
                }
                .padding(BIRGELayout.l)
                .background(
                    RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                                .stroke(
                                    BIRGEColors.textOnBrand.opacity(0.14),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal, BIRGELayout.m)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: store.step)

                Spacer()
                Spacer()
            }

            // Error banner overlay
            if let errorMessage = store.errorMessage {
                VStack {
                    errorBanner(message: errorMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .animation(reduceMotion ? nil : .spring(duration: 0.4), value: store.errorMessage)
                .padding(.top, BIRGELayout.xxxl + BIRGELayout.xs)
            }

            // Loading overlay
            if store.isLoading {
                loadingOverlay
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            resendTimerTask?.cancel()
        }
    }
}

// MARK: - Subviews

private extension OTPView {

    var brandHeader: some View {
        VStack(spacing: BIRGELayout.xs) {
            Image(systemName: "car.fill")
                .font(BIRGEFonts.verifyCode)
                .foregroundStyle(BIRGEColors.textOnBrand)

            Text("BIRGE")
                .font(BIRGEFonts.heroNumber)
                .foregroundStyle(BIRGEColors.textOnBrand)

            Text("Поехали вместе")
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textOnBrand.opacity(0.72))
        }
    }

    var phoneInputSection: some View {
        VStack(spacing: BIRGELayout.m) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                Text("Номер телефона")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textOnBrand.opacity(0.78))

                HStack(spacing: BIRGELayout.xs) {
                    Text("+7")
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.textOnBrand)
                        .padding(.horizontal, BIRGELayout.xs)
                        .padding(.vertical, BIRGELayout.xs)
                        .background(
                            RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                                .fill(BIRGEColors.surfacePrimary.opacity(0.22))
                        )

                    TextField("700 123 45 67", text: phoneBinding)
                        .keyboardType(.phonePad)
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.textOnBrand)
                        .tint(BIRGEColors.textOnBrand)
                        .padding(.horizontal, BIRGELayout.s)
                        .padding(.vertical, BIRGELayout.xs)
                        .background(
                            RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                                .fill(BIRGEColors.surfacePrimary.opacity(0.18))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                                .stroke(
                                    BIRGEColors.textOnBrand.opacity(0.14),
                                    lineWidth: 1
                                )
                        )
                }
            }

            BIRGEPrimaryButton(title: "Получить код", isLoading: store.isLoading) {
                store.send(.sendOTPTapped)
            }
            .disabled(store.phoneNumber.count < 10 || store.isLoading)
            .opacity(store.phoneNumber.count >= 10 ? 1 : 0.55)
        }
    }

    var codeInputSection: some View {
        VStack(spacing: BIRGELayout.m) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                Text("Код подтверждения")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textOnBrand.opacity(0.78))

                Text("Код отправлен на +7 \(store.phoneNumber)")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textOnBrand.opacity(0.62))

                otpBoxes
                    .padding(.top, BIRGELayout.xs)

                resendRow
                    .padding(.top, BIRGELayout.xxs)
            }

            BIRGEPrimaryButton(title: "Войти", isLoading: store.isLoading) {
                store.send(.verifyTapped)
            }
            .disabled(store.otpCode.count != 6 || store.isLoading)
            .opacity(store.otpCode.count == 6 ? 1 : 0.55)
        }
        .onAppear {
            isCodeFieldFocused = true
            startResendTimer()
        }
        .onChange(of: store.step) { _, step in
            guard step == .code else { return }
            isCodeFieldFocused = true
            startResendTimer()
        }
    }

    var otpBoxes: some View {
        ZStack {
            TextField("", text: codeBinding)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFieldFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)

            HStack(spacing: BIRGELayout.xxs) {
                ForEach(0..<6, id: \.self) { index in
                    otpBox(at: index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isCodeFieldFocused = true
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Код подтверждения: \(store.otpCode)")
        }
    }

    func otpBox(at index: Int) -> some View {
        let characters = Array(store.otpCode.prefix(6))
        let hasError = store.errorMessage != nil
        let isFocused = isCodeFieldFocused && index == min(store.otpCode.count, 5)
        let value = index < characters.count ? String(characters[index]) : ""

        return Text(value)
            .font(BIRGEFonts.otpDigit)
            .foregroundStyle(BIRGEColors.textPrimary)
            .frame(width: 56, height: 64)
            .background(
                RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                    .fill(hasError ? BIRGEColors.danger.opacity(0.14) : BIRGEColors.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                    .stroke(
                        hasError ? BIRGEColors.danger : (isFocused ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary.opacity(0.28)),
                        lineWidth: hasError || isFocused ? 2 : 1
                    )
            )
    }

    var resendRow: some View {
        Group {
            if resendSecondsRemaining > 0 {
                Text("Повторить через 0:\(String(format: "%02d", resendSecondsRemaining))")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textOnBrand.opacity(0.68))
            } else {
                Button("Повторить код") {
                    store.send(.sendOTPTapped)
                    startResendTimer()
                }
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textOnBrand)
                .birgeTapTarget()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    func startResendTimer() {
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

    func errorBanner(message: String) -> some View {
        BIRGEToast(message: message, style: .error)
            .padding(.horizontal, BIRGELayout.m)
    }

    var loadingOverlay: some View {
        ZStack {
            BIRGEColors.overlay
                .ignoresSafeArea()
            ProgressView()
                .tint(BIRGEColors.textOnBrand)
                .scaleEffect(1.5)
                .padding(BIRGELayout.xl)
                .background(
                    RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                        .fill(.ultraThinMaterial)
                )
        }
    }

    // MARK: - Bindings

    var phoneBinding: Binding<String> {
        Binding(
            get: { store.phoneNumber },
            set: { store.send(.phoneChanged($0)) }
        )
    }

    var codeBinding: Binding<String> {
        Binding(
            get: { store.otpCode },
            set: { store.send(.otpChanged(String($0.filter(\.isNumber).prefix(6)))) }
        )
    }
}

// MARK: - Preview

#Preview {
    OTPView(
        store: Store(initialState: OTPFeature.State()) {
            OTPFeature()
        }
    )
}
