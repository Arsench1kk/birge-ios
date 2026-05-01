#!/bin/bash

# Configuration
BUNDLE_ID="arsen.abdukhalyk.BIRGEPassenger"
PHONE="+77771234567"
DEVICE="iPhone 15"

echo "🚀 Starting E2E Setup..."

# 1. Boot simulator
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator

# 2. Launch app
echo "📱 Launching app..."
xcrun simctl launch "$DEVICE" "$BUNDLE_ID"

# 3. Wait for app to load (heuristic)
sleep 5

# 4. Auto-input via AppleScript
echo "⌨️ Typing phone number..."
osascript <<EOD
tell application "System Events"
    tell process "Simulator"
        set frontmost to true
        keystroke "$PHONE"
        keystroke return
    end tell
end tell
EOD

echo "✅ Done! Check the simulator."
