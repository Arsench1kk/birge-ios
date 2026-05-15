//
//  OTPFeatureTests.swift
//  BIRGEPassengerTests
//
//  Unit tests for the OTPFeature TCA Reducer.
//

import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class OTPFeatureTests: XCTestCase {
    
    func testOTPRequestSuccess() async {
        let store = TestStore(initialState: OTPFeature.State()) {
            OTPFeature()
        } withDependencies: {
            $0.authClient.requestOTP = { _ in } // Mock success
        }
        
        await store.send(.phoneChanged("+7777123456")) {
            $0.phoneNumber = "+7777123456"
        }
        
        await store.send(.sendOTPTapped) {
            $0.isLoading = true
        }
        
        await store.receive(\._otpRequestSucceeded) {
            $0.isLoading = false
            $0.step = .code // waiting_for_verification
        }
    }
    
    func testOTPVerifySuccess() async {
        let authResponse = AuthResponse(
            accessToken: "access",
            refreshToken: "refresh",
            role: "passenger",
            userId: "123"
        )
        
        let store = TestStore(initialState: OTPFeature.State(
            phoneNumber: "+7777123456",
            otpCode: "123456",
            step: .code
        )) {
            OTPFeature()
        } withDependencies: {
            $0.authClient.verifyOTP = { _, _ in authResponse }
            $0.keychainClient.save = { _, _ in } // Mock save
        }
        
        await store.send(.verifyTapped) {
            $0.isLoading = true
        }
        
        await store.receive(\._verifySucceeded, OTPAuthentication(role: "passenger", phone: "+7777123456")) {
            $0.isLoading = false
        }
        
        await store.receive(\.delegate.authenticated, OTPAuthentication(role: "passenger", phone: "+7777123456"))
    }
    
    func testOTPVerifyFailure() async {
        let store = TestStore(initialState: OTPFeature.State(
            phoneNumber: "+7777123456",
            otpCode: "000000",
            step: .code
        )) {
            OTPFeature()
        } withDependencies: {
            $0.authClient.verifyOTP = { _, _ in throw AuthError.verificationFailed }
            $0.keychainClient.save = { _, _ in }
        }
        
        await store.send(.verifyTapped) {
            $0.isLoading = true
        }
        
        await store.receive(\._verifyFailed, AuthError.verificationFailed.localizedDescription) {
            $0.isLoading = false
            $0.errorMessage = AuthError.verificationFailed.localizedDescription
        }
    }

    func testChangePhoneTappedReturnsToPhoneStep() async {
        let store = TestStore(initialState: OTPFeature.State(
            phoneNumber: "+7777123456",
            otpCode: "481",
            step: .code,
            errorMessage: "Неверный код."
        )) {
            OTPFeature()
        }

        await store.send(.changePhoneTapped) {
            $0.step = .phone
            $0.otpCode = ""
            $0.errorMessage = nil
            // phoneNumber is preserved so the user can edit it
            $0.phoneNumber = "+7777123456"
        }
    }
}
