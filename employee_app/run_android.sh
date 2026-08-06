#!/usr/bin/env bash
# Starts the Android emulator (if not already running) and launches the
# Flutter employee_app on it.
set -euo pipefail

ANDROID_SDK="/opt/homebrew/share/android-commandlinetools"
EMULATOR="$ANDROID_SDK/emulator/emulator"
ADB="$ANDROID_SDK/platform-tools/adb"
AVD_NAME="${1:-Pixel_7_API_35}"

cd "$(dirname "$0")"

if ! "$ADB" devices | grep -q "emulator-.*device$"; then
    echo "Starting Android emulator ($AVD_NAME)..."
    "$EMULATOR" -avd "$AVD_NAME" -netdelay none -netspeed full >/tmp/android_emulator.log 2>&1 &
    echo "Waiting for emulator to boot..."
    "$ADB" wait-for-device
    until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
        sleep 2
    done
    echo "Emulator ready."
else
    echo "Emulator already running."
fi

if [ ! -f .env ]; then
    echo "No .env found — copying .env.example (edit API_BASE_URL if needed)."
    cp .env.example .env
fi

echo "Launching Flutter app..."
flutter run
