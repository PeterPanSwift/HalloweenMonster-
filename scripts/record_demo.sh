#!/usr/bin/env bash
# Records the simulator screen while the UI test drives the app.
# Usage: record_demo.sh <simulator-udid> <output-dir>
set -euo pipefail

udid="$1"
out="$2"
mkdir -p "$out"
raw="$out/iphone-duo-demo.mov"

xcrun simctl io "$udid" recordVideo --codec=h264 --force "$raw" > "$out/recordVideo.log" 2>&1 &
recorder=$!
stop_recording() {
  if kill -0 "$recorder" 2>/dev/null; then
    kill -INT "$recorder"
    wait "$recorder" || true
  fi
}
trap stop_recording EXIT
sleep 3

set +e
xcodebuild test-without-building \
  -project HalloweenMonster.xcodeproj \
  -scheme HalloweenMonster \
  -destination "platform=iOS Simulator,id=$udid" \
  -derivedDataPath build \
  -parallel-testing-enabled NO \
  -resultBundlePath "$out/UITests.xcresult" \
  -only-testing:HalloweenMonsterUITests/DemoRecordingUITests
status=$?
set -e

sleep 1
stop_recording
trap - EXIT
cat "$out/recordVideo.log" || true
ls -lh "$out"
exit $status
