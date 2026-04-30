//
//  OTPFeatureTests.swift
//  BIRGEPassengerTests
//
//  Created by Арсен Абдухалық on 22.04.2026.
//

import ComposableArchitecture
import Testing

@testable import BIRGEPassenger

@Suite("OTP Feature Tests")
struct OTPFeatureTests {

    @Test("Request OTP transitions to enter code step")
    func requestOTP() async {
        let store = TestStore(
            initialState: OTPFeature.State(phone: "+77001234567")
        ) {
            OTPFeature()
        } withDependencies: {
            $0.authClient.requestOTP = { _ in }
            $0.keychainClient = .testValue
        }

        await store.send(.view(.requestOTPTapped)) {
            $0.isLoading = true
        }

        await store.receive(\.otpRequestSucceeded) {
            $0.isLoading = false
            $0.step = .enterCode
        }
    }

    @Test("Verify OTP success emits delegate authenticated")
    func verifyOTPSuccess() async {
        let jwt = JWT(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date(timeIntervalSince1970: 1_000_000)
        )

        let store = TestStore(
            initialState: OTPFeature.State(
                phone: "+77001234567",
                code: "123456",
                step: .enterCode
            )
        ) {
            OTPFeature()
        } withDependencies: {
            $0.authClient.verifyOTP = { _, _ in jwt }
            $0.keychainClient.save = { _, _ in }
        }

        await store.send(.view(.verifyOTPTapped)) {
            $0.isLoading = true
        }

        await store.receive(\.otpVerifySucceeded) {
            $0.isLoading = false
        }

        await store.receive(\.delegate.authenticated)
    }

    @Test("Verify OTP failure sets error message")
    func verifyOTPFailure() async {
        let store = TestStore(
            initialState: OTPFeature.State(
                phone: "+77001234567",
                code: "000000",
                step: .enterCode
            )
        ) {
            OTPFeature()
        } withDependencies: {
            $0.authClient.verifyOTP = { _, _ in
                throw AuthError.verificationFailed
            }
            $0.keychainClient = .testValue
        }

        await store.send(.view(.verifyOTPTapped)) {
            $0.isLoading = true
        }

        await store.receive(\.otpVerifyFailed) {
            $0.isLoading = false
            $0.errorMessage = AuthError.verificationFailed.localizedDescription
        }
    }

    @Test("Request OTP failure sets error message")
    func requestOTPFailure() async {
        let store = TestStore(
            initialState: OTPFeature.State(phone: "+77001234567")
        ) {
            OTPFeature()
        } withDependencies: {
            $0.authClient.requestOTP = { _ in
                throw AuthError.requestFailed
            }
            $0.keychainClient = .testValue
        }

        await store.send(.view(.requestOTPTapped)) {
            $0.isLoading = true
        }

        await store.receive(\.otpRequestFailed) {
            $0.isLoading = false
            $0.errorMessage = AuthError.requestFailed.localizedDescription
        }
    }
}
