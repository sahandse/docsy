#!/usr/bin/env bash
set -eu

adb wait-for-device

# Wait for Android framework and Package Manager to be ready.
ready=0
for attempt in $(seq 1 60); do
  booted="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
  if [ "$booted" = "1" ] && adb shell cmd package list packages >/dev/null 2>&1; then
    ready=1
    break
  fi
  echo "Waiting for Android services (attempt $attempt/60)..."
  sleep 5
done
if [ "$ready" -ne 1 ]; then
  echo "Android Package Manager did not become ready."
  adb logcat -d -t 300 || true
  exit 1
fi

installed=0
for attempt in 1 2 3; do
  if adb install --no-streaming artifacts/app-release.apk; then
    installed=1
    break
  fi
  echo "APK installation attempt $attempt failed; waiting for Android services..."
  sleep 10
done
if [ "$installed" -ne 1 ]; then
  adb logcat -d -t 300 || true
  exit 1
fi

adb shell monkey -p com.sahandse.docsy 1
sleep 5
adb shell pidof com.sahandse.docsy
