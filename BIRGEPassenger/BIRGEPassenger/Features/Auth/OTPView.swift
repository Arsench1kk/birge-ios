//
//  OTPView.swift
//  BIRGEPassenger
//
//  Thin host that switches between OTPPhoneView and OTPCodeView
//  based on OTPFeature.State.step. Handles the error banner overlay
//  and step transition animation.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

// MARK: - OTPView (host)

struct OTPView: View {
    @Bindable var store: StoreOf<OTPFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            // Step content
            Group {
                switch store.step {
                case .phone:
                    OTPPhoneView(store: store)
                        .transition(stepTransition(insertion: .leading, removal: .leading))

                case .code:
                    OTPCodeView(store: store)
                        .transition(stepTransition(insertion: .trailing, removal: .trailing))
                }
            }
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.3),
                value: store.step
            )

            // Error banner — floats above content
            if let errorMessage = store.errorMessage {
                BIRGEToast(message: errorMessage, style: .error)
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.top, BIRGELayout.xxxl)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(
                        reduceMotion ? nil : .spring(duration: 0.4),
                        value: store.errorMessage
                    )
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
    }

    private func stepTransition(insertion: Edge, removal: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: insertion).combined(with: .opacity),
            removal: .move(edge: removal).combined(with: .opacity)
        )
    }
}

// MARK: - OTPNavHeader
//
// Shared nav header for phone and code steps.
// Matches the mockup's setup-nav pattern:
// back chevron (left) + step label (center).
//
// `backAction`: when provided, called instead of dismiss().
// Phone step passes nil → dismiss() pops the OTP screen.
// Code step passes a closure → sends .changePhoneTapped to the reducer.

struct OTPNavHeader: View {
    let stepLabel: String
    var backAction: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button {
                if let backAction {
                    backAction()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .frame(width: BIRGELayout.minTapTarget, height: BIRGELayout.minTapTarget)
            }
            .accessibilityLabel("Назад")

            Spacer()

            Text(stepLabel)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)

            Spacer()

            // Invisible spacer to balance the back button
            Color.clear
                .frame(width: BIRGELayout.minTapTarget, height: BIRGELayout.minTapTarget)
        }
        .padding(.horizontal, BIRGELayout.s)
        .frame(height: BIRGELayout.minTapTarget)
    }
}

// MARK: - Previews

#Preview("Phone step") {
    OTPView(
        store: Store(initialState: OTPFeature.State(step: .phone)) {
            OTPFeature()
        }
    )
}

#Preview("Code step") {
    OTPView(
        store: Store(initialState: OTPFeature.State(
            phoneNumber: "7001234567",
            step: .code
        )) {
            OTPFeature()
        }
    )
}

#Preview("Code step — error") {
    OTPView(
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
