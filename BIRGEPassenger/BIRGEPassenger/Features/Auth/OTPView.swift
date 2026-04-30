//
//  OTPView.swift
//  BIRGEPassenger
//

import ComposableArchitecture
import SwiftUI

struct OTPView: View {
    @Bindable var store: StoreOf<OTPFeature>

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.08, green: 0.06, blue: 0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo / Brand
                brandHeader

                Spacer().frame(height: 48)

                // Content card
                VStack(spacing: 24) {
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
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.35), value: store.step)

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
                .animation(.spring(duration: 0.4), value: store.errorMessage)
                .padding(.top, 60)
            }

            // Loading overlay
            if store.isLoading {
                loadingOverlay
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews

private extension OTPView {

    var brandHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.8, blue: 0.55),
                            Color(red: 0.2, green: 0.65, blue: 0.9),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("BIRGE")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Поехали вместе")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    var phoneInputSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Номер телефона")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 12) {
                    Text("+7")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )

                    TextField("700 123 45 67", text: phoneBinding)
                        .keyboardType(.phonePad)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white)
                        .tint(Color(red: 0.35, green: 0.8, blue: 0.55))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                }
            }

            actionButton(
                title: "Получить код",
                isEnabled: store.phoneNumber.count >= 10
            ) {
                store.send(.sendOTPTapped)
            }
        }
    }

    var codeInputSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Код подтверждения")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))

                Text("Код отправлен на +7 \(store.phoneNumber)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))

                TextField("000000", text: codeBinding)
                    .keyboardType(.numberPad)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tint(Color(red: 0.35, green: 0.8, blue: 0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            }

            actionButton(
                title: "Войти",
                isEnabled: store.otpCode.count == 6
            ) {
                store.send(.verifyTapped)
            }
        }
    }

    func actionButton(
        title: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isEnabled
                                ? LinearGradient(
                                    colors: [
                                        Color(red: 0.3, green: 0.75, blue: 0.5),
                                        Color(red: 0.2, green: 0.6, blue: 0.85),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.3),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                )
        }
        .disabled(!isEnabled)
    }

    func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(0.85))
        )
        .padding(.horizontal, 20)
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
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
            set: { store.send(.otpChanged($0)) }
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
