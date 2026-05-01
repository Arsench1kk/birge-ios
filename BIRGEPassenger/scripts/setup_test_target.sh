#!/bin/bash
#
# scripts/setup_test_target.sh
# BIRGEPassenger Test Target Setup & Validation Script
#

set -e

PROJECT_DIR=$(dirname "$0")/..
PBXPROJ_PATH="$PROJECT_DIR/BIRGEPassenger.xcodeproj/project.pbxproj"

echo "🔍 Checking for BIRGEPassengerTests target..."

if grep -q "BIRGEPassengerTests" "$PBXPROJ_PATH"; then
    echo "✅ BIRGEPassengerTests target already exists in the Xcode project."
    echo "ℹ️ Ensure that the new test files are assigned to the BIRGEPassengerTests target membership in Xcode."
else
    echo "⚠️ BIRGEPassengerTests target not found!"
    echo "To complete setup, open Xcode:"
    echo "1. Go to File > New > Target..."
    echo "2. Select 'Unit Testing Bundle'"
    echo "3. Name it 'BIRGEPassengerTests'"
    echo "4. Add the generated test files to this target."
fi

echo ""
echo "🚀 Validation complete."
echo "You can run tests from the command line using:"
echo "xcodebuild test -scheme BIRGEPassenger -destination 'platform=iOS Simulator,name=iPhone 17 Pro'"
