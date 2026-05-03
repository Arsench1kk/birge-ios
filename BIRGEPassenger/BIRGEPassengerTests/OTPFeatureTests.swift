//
//  OTPFeatureTests.swift
//  BIRGEPassengerTests
//
//  Unit tests for the OTPFeature TCA Reducer.
//

import ComposableArchitecture
import ConcurrencyExtras
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
        let savedValues = LockIsolated<[String: String]>([:])
        
        let store = TestStore(initialState: OTPFeature.State(
            phoneNumber: "+7777123456",
            otpCode: "123456",
            step: .code
        )) {
            OTPFeature()
        } withDependencies: {
            $0.authClient.verifyOTP = { _, _ in authResponse }
            $0.keychainClient.save = { key, value in
                savedValues.withValue { $0[key] = value }
            }
        }
        
        await store.send(.verifyTapped) {
            $0.isLoading = true
        }
        
        await store.receive(\._verifySucceeded, "passenger") {
            $0.isLoading = false
        }
        
        await store.receive(\.delegate.authenticated, "passenger")

        XCTAssertEqual(savedValues.value[KeychainClient.Keys.accessToken], "access")
        XCTAssertEqual(savedValues.value[KeychainClient.Keys.refreshToken], "refresh")
        XCTAssertEqual(savedValues.value[KeychainClient.Keys.userID], "123")
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
}
