# BIRGE E2E OTP Flow Tests

This document describes how to execute the End-to-End integration tests for the OTP Flow in the BIRGE iOS app.

## Prerequisites

1. **Vapor Backend (`birge-vapor`)**: Must be running locally on `localhost:8080`.
   ```bash
   cd birge-vapor
   swift run
   ```
2. **Infrastructure**: PostgreSQL 16 and Redis 7 must be active and accessible by the Vapor backend.
3. **Simulator**: Tests use the iOS Simulator. Ensure the target simulator (e.g., `iPhone 17 Pro`) is installed, or adjust the destination parameter below.

## Running the Tests

To run the automated XCTest suite via the command line:

```bash
xcodebuild test -scheme BIRGEPassenger \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BIRGEPassengerTests/OTPFlowE2ETests
```

### Expected Output
You should see output indicating all tests passed successfully:
```
Test Suite 'OTPFlowE2ETests' started...
Test Case '-[BIRGEPassengerTests.OTPFlowE2ETests testOTPFlowSuccess]' passed (1.234 seconds).
Test Case '-[BIRGEPassengerTests.OTPFlowE2ETests testOTPFlowInvalidCode]' passed (0.123 seconds).
Test Case '-[BIRGEPassengerTests.OTPFlowE2ETests testOTPKeychainPersistence]' passed (0.045 seconds).
Test Suite 'OTPFlowE2ETests' passed (3 tests)
```
The file `/tmp/birge-otp.log` will contain the new OTP entries generated during the test.

## Troubleshooting

- **Test times out waiting for OTP**: 
  - Verify Vapor is actively running on `localhost:8080`.
  - Check file permissions. Vapor must be able to write to `/tmp/birge-otp.log` and the iOS test bundle must be able to read from it.
- **Keychain Errors**:
  - The tests use the actual `Security` framework. If the Simulator's Keychain state becomes corrupted, navigate to `Device > Erase All Content and Settings` in the Simulator menu.
