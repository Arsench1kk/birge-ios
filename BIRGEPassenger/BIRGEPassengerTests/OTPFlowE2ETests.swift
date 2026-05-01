//
//  OTPFlowE2ETests.swift
//  BIRGEPassengerTests
//
//  E2E and Integration tests for the OTP Authentication Flow.
//

import XCTest
import ComposableArchitecture
@testable import BIRGEPassenger

@MainActor
final class OTPFlowE2ETests: XCTestCase {
    
    private let testPhone = "+7777123456"
    private let alternatePhone = "+7777123457"
    private let logPath = "/tmp/birge-otp.log"
    private let liveE2EEnvironmentKey = "RUN_LIVE_OTP_E2E"
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try cleanKeychain()
    }

    override func tearDownWithError() throws {
        try cleanKeychain()
        try super.tearDownWithError()
    }
    
    private func cleanKeychain() throws {
        try? KeychainClient.liveValue.delete("birge_access_token")
        try? KeychainClient.liveValue.delete("birge_refresh_token")
        try? KeychainClient.liveValue.delete("birge_user_id")
    }

    private func updateUnauthenticatedState(
        _ state: inout AppFeature.State,
        _ update: (inout OTPFeature.State) -> Void
    ) {
        guard case var .unauthenticated(otpState) = state else {
            XCTFail("Expected unauthenticated app state")
            return
        }
        update(&otpState)
        state = .unauthenticated(otpState)
    }

    // a) Successful E2E test using live backend and reading OTP from log
    func testOTPFlowSuccess() async throws {
        guard ProcessInfo.processInfo.environment[liveE2EEnvironmentKey] == "1" else {
            throw XCTSkip(
                "Set \(liveE2EEnvironmentKey)=1 and ensure Vapor writes \(logPath) to run the live OTP E2E test."
            )
        }

        // Uses the real AuthClient. Ensure Vapor is running locally.
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.authClient = .liveValue 
            $0.keychainClient = .liveValue
        }
        
        let startByteCount = OTPLogReader.byteCount(logPath: logPath)
        
        // 1. Enter Phone
        await store.send(.otp(.phoneChanged(testPhone))) {
            self.updateUnauthenticatedState(&$0) {
                $0.phoneNumber = self.testPhone
            }
        }
        
        // 2. Send OTP Request
        await store.send(.otp(.sendOTPTapped)) {
            self.updateUnauthenticatedState(&$0) {
                $0.isLoading = true
            }
        }
        
        await store.receive(\.otp._otpRequestSucceeded, timeout: .seconds(5)) {
            self.updateUnauthenticatedState(&$0) {
                $0.isLoading = false
                $0.step = .code
            }
        }
        
        // 3. Read OTP from file
        let otpMatch = try await OTPLogReader.waitForLatestOTP(
            for: testPhone,
            logPath: logPath,
            startingAtByteOffset: startByteCount,
            timeout: 5.0
        )
        
        // 4. Enter Code
        await store.send(.otp(.otpChanged(otpMatch.otpCode))) {
            self.updateUnauthenticatedState(&$0) {
                $0.otpCode = otpMatch.otpCode
            }
        }
        
        // 5. Verify OTP
        await store.send(.otp(.verifyTapped)) {
            self.updateUnauthenticatedState(&$0) {
                $0.isLoading = true
            }
        }
        
        await store.receive(\.otp._verifySucceeded, timeout: .seconds(5)) {
            self.updateUnauthenticatedState(&$0) {
                $0.isLoading = false
            }
        }
        
        // Check transition to authenticated state
        await store.receive(\.otp.delegate.authenticated) {
            $0 = .authenticated(PassengerAppFeature.State())
        }
        
        // 6. Verify Keychain Token
        let token = try XCTUnwrap(KeychainClient.liveValue.load("birge_access_token"))
        XCTAssertFalse(token.isEmpty)
        
        // 7. Verify currentUser()
        let user = try await AuthClient.liveValue.currentUser()
        XCTAssertEqual(user.phone, testPhone)
    }

    // b) Invalid OTP test using isolated dependencies
    func testOTPFlowInvalidCode() async throws {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            // Mock network layer to force verification failure
            $0.authClient.verifyOTP = { _, _ in throw AuthError.verificationFailed }
            $0.keychainClient = .liveValue
        }
        
        await store.send(.otp(.phoneChanged(alternatePhone))) {
            self.updateUnauthenticatedState(&$0) {
                $0.phoneNumber = self.alternatePhone
            }
        }
        
        await store.send(.otp(.otpChanged("000000"))) {
            self.updateUnauthenticatedState(&$0) {
                $0.otpCode = "000000"
            }
        }
        
        await store.send(.otp(.verifyTapped)) {
            self.updateUnauthenticatedState(&$0) {
                $0.isLoading = true
            }
        }
        
        // Expect failure
        await store.receive(\.otp._verifyFailed, timeout: .seconds(5)) {
            self.updateUnauthenticatedState(&$0) {
                $0.isLoading = false
                $0.errorMessage = "Неверный код. Попробуйте ещё раз."
            }
        }
        
        // Verify keychain was not modified
        let token = try? KeychainClient.liveValue.load("birge_access_token")
        XCTAssertNil(token)
    }

    // c) Persistence verification
    func testOTPKeychainPersistence() async throws {
        // 1. Save dummy token mimicking successful login
        let mockToken = "mock_persisted_token_123"
        try KeychainClient.liveValue.save("birge_access_token", mockToken)
        
        // 2. Simulate Cold Boot (AppFeature.init reads Keychain synchronously)
        let appState = AppFeature.State()
        
        // 3. Verify App boots directly into authenticated state
        guard case .authenticated = appState else {
            XCTFail("App did not restore authenticated state from Keychain")
            return
        }
        
        let loadedToken = try KeychainClient.liveValue.load("birge_access_token")
        XCTAssertEqual(loadedToken, mockToken)
    }
}
