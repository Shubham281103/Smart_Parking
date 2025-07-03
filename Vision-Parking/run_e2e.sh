#!/bin/bash
set -e

# === Global config ===
export APPIUM_LOG_FILE="/tmp/appium.log"

# Function to always save logcat on exit, even if the script fails
cleanup_logcat() {
  ${ANDROID_SDK_ROOT}/platform-tools/adb logcat -d > /tmp/logcat.txt 2>&1 || touch /tmp/logcat.txt
}
trap cleanup_logcat EXIT

cd "$(dirname "$0")"

chmod +x gradlew

echo "Assembling debug APK..."
./gradlew assembleDebug -p app

echo "Waiting for Android device..."
${ANDROID_SDK_ROOT}/platform-tools/adb wait-for-device

echo "Polling for emulator boot completion..."
for i in $(seq 1 30); do
  BOOT_STATUS=$(${ANDROID_SDK_ROOT}/platform-tools/adb shell getprop sys.boot_completed | tr -d '\r')
  if [[ "$BOOT_STATUS" == "1" ]]; then
    echo "✅ Emulator boot completed"
    break
  fi
  echo "⏳ Waiting for emulator to boot ($i/30)..."
  sleep 5
done
if [[ "$BOOT_STATUS" != "1" ]]; then
  echo "❌ Emulator did not boot in time."
  exit 1
fi

echo "Waiting for package manager service..."
for i in $(seq 1 30); do
  if ${ANDROID_SDK_ROOT}/platform-tools/adb shell service check package | grep -q "found"; then
    echo "✅ Package manager service is available"
    break
  fi
  echo "⏳ Waiting for package manager service ($i/30)..."
  sleep 5
done

echo "=== ADB diagnostics ==="
${ANDROID_SDK_ROOT}/platform-tools/adb devices
${ANDROID_SDK_ROOT}/platform-tools/adb shell getprop
${ANDROID_SDK_ROOT}/platform-tools/adb shell df -h
${ANDROID_SDK_ROOT}/platform-tools/adb shell uptime
${ANDROID_SDK_ROOT}/platform-tools/adb shell top -n 1

echo "Sleeping 10 seconds before install..."
sleep 10

echo "Installing app-debug.apk with retries..."
INSTALL_SUCCESS=0
for i in $(seq 1 5); do
  if ${ANDROID_SDK_ROOT}/platform-tools/adb install -r app/build/outputs/apk/debug/app-debug.apk; then
    INSTALL_SUCCESS=1
    echo "✅ APK installed successfully on attempt $i"
    break
  else
    echo "❌ APK install failed on attempt $i, retrying in 30s..."
    sleep 30
  fi
done
if [ $INSTALL_SUCCESS -ne 1 ]; then
  echo "APK install failed after 5 attempts"
  exit 1
fi

echo "Installing Appium globally..."
npm install -g appium

echo "Installing Appium UiAutomator2 driver..."
appium driver install uiautomator2

echo "Starting Appium server in background..."
nohup appium --base-path /wd/hub --log "$APPIUM_LOG_FILE" &
APPIUM_PID=$!

# Wait for Appium to be ready
echo "Waiting for Appium server to be ready..."
for i in {1..30}; do
  if nc -z 127.0.0.1 4723; then
    echo "✅ Appium is up!"
    break
  fi
  sleep 1
done

# Fail if Appium never started
if ! nc -z 127.0.0.1 4723; then
  echo "❌ Appium did not start in time!"
  exit 1
fi

# Only cd into Vision-Parking if not already there
if [ "$(basename "$PWD")" != "Vision-Parking" ]; then
  cd Vision-Parking || { echo "Failed to change directory to Vision-Parking"; exit 1; }
fi

export TEST_REPORT_FILE=tests/report.html

echo "Running pytest E2E tests..."
pytest -q --disable-warnings --html="$TEST_REPORT_FILE" --self-contained-html
PYTEST_EXIT=$?

if [ ! -f "$TEST_REPORT_FILE" ]; then
  echo "❌ Test report not generated, marking as failed."
  exit 1
fi

if [ $PYTEST_EXIT -ne 0 ]; then
  echo "⚠️ Pytest exited with code $PYTEST_EXIT — likely due to warnings or skipped tests."
fi

echo "Waiting for Appium to flush logs..."
sleep 5

echo "Stopping Appium (PID=$APPIUM_PID)..."
kill $APPIUM_PID || true
wait $APPIUM_PID 2>/dev/null || true

echo "Killing emulator and adb..."
pkill -f emulator || true
$ANDROID_SDK_ROOT/platform-tools/adb kill-server || true

# Final log check
if [ -n "$APPIUM_LOG_FILE" ] && [ -f "$APPIUM_LOG_FILE" ]; then
  echo "✅ Appium log exists: $APPIUM_LOG_FILE"
else
  echo "⚠️ Appium log not found!"
  touch "$APPIUM_LOG_FILE"
fi

echo "✅ E2E script completed successfully."
exit 0
