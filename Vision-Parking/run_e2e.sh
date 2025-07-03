#!/bin/bash
set -e

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

echo "Disabling animations for faster tests..."
${ANDROID_SDK_ROOT}/platform-tools/adb shell settings put global window_animation_scale 0.0 || echo "⚠️ Failed to set window animation scale"
${ANDROID_SDK_ROOT}/platform-tools/adb shell settings put global transition_animation_scale 0.0 || echo "⚠️ Failed to set transition animation scale"
${ANDROID_SDK_ROOT}/platform-tools/adb shell settings put global animator_duration_scale 0.0 || echo "⚠️ Failed to set animator duration scale"

echo "Installing app-debug.apk..."
${ANDROID_SDK_ROOT}/platform-tools/adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "Installing Appium globally..."
npm install -g appium

echo "Installing Appium UiAutomator2 driver..."
appium driver install uiautomator2

echo "Starting Appium server in background..."
nohup appium --log "$APPIUM_LOG_FILE" &
sleep 15

echo "Running pytest E2E tests..."
pytest --maxfail=1 --disable-warnings --html="$TEST_REPORT_FILE" --self-contained-html 
