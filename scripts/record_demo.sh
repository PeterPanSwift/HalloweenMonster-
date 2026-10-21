#!/usr/bin/env bash
# Records the simulator screen while the UI test drives the app.
# Usage: record_demo.sh <simulator-udid> <output-dir>
#
# iPhone Duo has two panels. Without --display, recordVideo picks the inner panel, which is
# dark while the device is folded, so every display is recorded and the busiest video is kept.
set -euo pipefail

udid="$1"
out="$2"
mkdir -p "$out/displays"

xcrun simctl io "$udid" enumerate > "$out/displays.txt" 2>&1 || true
cat "$out/displays.txt"

displays=$(sed -nE 's/^[[:space:]]*Device Name:[[:space:]]*(.+)$/\1/p' "$out/displays.txt" | sort -u)
if [[ -z "$displays" ]]; then
  displays="default"
fi
echo "Recording displays: $(echo $displays)"

recorders=()
for display in $displays; do
  args=(--codec=h264 --force)
  [[ "$display" != "default" ]] && args+=("--display=$display")
  xcrun simctl io "$udid" recordVideo "${args[@]}" "$out/displays/$display.mov" > "$out/displays/$display.log" 2>&1 &
  recorders+=($!)
done

stop_recording() {
  for pid in "${recorders[@]}"; do
    kill -INT "$pid" 2>/dev/null || true
  done
  for pid in "${recorders[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
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

for log in "$out"/displays/*.log; do
  echo "== $log"
  cat "$log"
done
ls -l "$out/displays"

# Keep the biggest recording: the panel that showed the app has by far the most frames.
best=$(ls -S "$out"/displays/*.mov 2>/dev/null | head -n 1 || true)
if [[ -z "$best" ]]; then
  echo "::error::No video was recorded"
  exit 1
fi
echo "Using $best"
cp "$best" "$out/iphone-duo-demo.mov"
ls -lh "$out"
exit $status
