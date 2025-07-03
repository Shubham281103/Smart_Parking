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

# Restart adb server before install
${ANDROID_SDK_ROOT}/platform-tools/adb kill-server
${ANDROID_SDK_ROOT}/platform-tools/adb start-server

echo "Installing app-debug.apk..."
start=$(date +%s)
timeout 120 ${ANDROID_SDK_ROOT}/platform-tools/adb install -r app/build/outputs/apk/debug/app-debug.apk
status=$?
end=$(date +%s)
echo "APK install took $((end - start)) seconds"
if [ $status -ne 0 ]; then
  echo "APK install failed or timed out"
  ${ANDROID_SDK_ROOT}/platform-tools/adb logcat -d | tail -n 100
  exit 1
fi

echo "Installing Appium globally..."
npm install -g appium

echo "Installing Appium UiAutomator2 driver..."
appium driver install uiautomator2

echo "Starting Appium server in background..."
nohup appium --base-path /wd/hub --log "$APPIUM_LOG_FILE" &
sleep 15

echo "Running pytest E2E tests..."
pytest --maxfail=1 --disable-warnings --html="$TEST_REPORT_FILE" --self-contained-html 
