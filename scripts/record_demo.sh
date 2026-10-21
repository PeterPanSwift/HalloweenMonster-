#!/usr/bin/env bash
# Records the simulator screen while the UI test drives the app.
# Usage: record_demo.sh <simulator-udid> <output-dir>
#
# iPhone Duo has two panels: "primary" is the outer screen (used while folded, which is how the
# simulator boots) and "primary-1" is the inner one. Without --display, recordVideo picks the
# inner panel, which stays dark while folded. Only one recording per device can run at a time.
set -euo pipefail

udid="$1"
out="$2"
display="${RECORD_DISPLAY:-primary}"
mkdir -p "$out"
video="$out/iphone-duo-demo.mov"

xcrun simctl io "$udid" enumerate > "$out/displays.txt" 2>&1 || true
grep -E "^\s+\([0-9]+\)|Device Name:|Pixel Size:|Screen Type:" "$out/displays.txt" || true

echo "Recording display: $display"
xcrun simctl io "$udid" recordVideo --codec=h264 --force --display="$display" "$video" > "$out/recordVideo.log" 2>&1 &
recorder=$!
stop_recording() {
  if kill -0 "$recorder" 2>/dev/null; then
    kill -INT "$recorder"
    wait "$recorder" || true
  fi
}
trap stop_recording EXIT
sleep 3
if ! kill -0 "$recorder" 2>/dev/null; then
  cat "$out/recordVideo.log"
  echo "::error::recordVideo exited before the test started"
  exit 1
fi

rec_start=$(date +%s)

set +e
# Note when the test starts waiting for the first monster: the app is on screen by then.
# Everything before it is the home screen while xcodebuild installs and launches the runner.
xcodebuild test-without-building \
  -project HalloweenMonster.xcodeproj \
  -scheme HalloweenMonster \
  -destination "platform=iOS Simulator,id=$udid" \
  -derivedDataPath build \
  -parallel-testing-enabled NO \
  -resultBundlePath "$out/UITests.xcresult" \
  -only-testing:HalloweenMonsterUITests/DemoRecordingUITests 2>&1 |
  while IFS= read -r line; do
    printf '%s\n' "$line"
    if [[ ! -f "$out/app_visible_at" && "$line" == *'Waiting'*'"monsterImage" Image to exist'* ]]; then
      date +%s > "$out/app_visible_at"
    fi
  done
status=${PIPESTATUS[0]}
set -e

trim=0
if [[ -f "$out/app_visible_at" ]]; then
  trim=$(( $(cat "$out/app_visible_at") - rec_start - 2 ))
  if (( trim < 0 )); then trim=0; fi
fi
echo "$trim" > "$out/trim_start_seconds"
echo "Idle seconds at the start of the recording: $trim"

sleep 1
stop_recording
trap - EXIT
cat "$out/recordVideo.log" || true
ls -lh "$out"
exit $status
