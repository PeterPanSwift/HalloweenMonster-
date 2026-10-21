#!/usr/bin/env bash
# Creates and boots an "iPhone Duo" simulator, downloading the iOS runtime if needed.
# Writes SIM_UDID to $GITHUB_ENV.
set -euo pipefail

DEVICE_NAME="${DEVICE_NAME:-iPhone Duo}"
work=$(mktemp -d)

find_device() {
  xcrun simctl list -j devicetypes > "$work/types.json"
  xcrun simctl list -j runtimes > "$work/runtimes.json"
  python3 - "$work/types.json" "$work/runtimes.json" "$DEVICE_NAME" <<'PY'
import json, sys
types = json.load(open(sys.argv[1]))["devicetypes"]
runtimes = json.load(open(sys.argv[2]))["runtimes"]
wanted = sys.argv[3].lower()

matches = [t for t in types if t["name"].lower() == wanted] or \
          [t for t in types if "duo" in t["name"].lower() or "iphone-duo" in t["identifier"].lower()]
if not matches:
    sys.exit(0)
device_type = matches[0]

def version_key(r):
    return tuple(int(p) for p in r["version"].split(".") if p.isdigit())

usable = [
    r for r in runtimes
    if r.get("isAvailable") and r.get("platform", "iOS") == "iOS"
    and any(s["identifier"] == device_type["identifier"] for s in r.get("supportedDeviceTypes", []))
]
if not usable:
    print(device_type["identifier"])
    sys.exit(0)
runtime = max(usable, key=version_key)
print(device_type["identifier"], runtime["identifier"])
PY
}

echo "== Device types =="
xcrun simctl list devicetypes | grep -i iphone || true
echo "== Runtimes =="
xcrun simctl list runtimes

read -r device_type runtime <<<"$(find_device) " || true
if [[ -z "${device_type:-}" || -z "${runtime:-}" ]]; then
  echo "iPhone Duo device type or a matching iOS runtime is missing; downloading the iOS platform…"
  xcodebuild -downloadPlatform iOS
  xcrun simctl list runtimes
  read -r device_type runtime <<<"$(find_device) " || true
fi

if [[ -z "${device_type:-}" ]]; then
  echo "::error::This Xcode has no '$DEVICE_NAME' simulator device type (needs Xcode 27.1+)"
  exit 1
fi
if [[ -z "${runtime:-}" ]]; then
  echo "::error::No installed iOS runtime supports $device_type"
  exit 1
fi

echo "Device type: $device_type"
echo "Runtime:     $runtime"
udid=$(xcrun simctl create "$DEVICE_NAME" "$device_type" "$runtime")
echo "Created $DEVICE_NAME: $udid"

xcrun simctl boot "$udid"
xcrun simctl bootstatus "$udid" -b
xcrun simctl ui "$udid" appearance dark || true
xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4 || true
open -a Simulator --args -CurrentDeviceUDID "$udid" || true

echo "SIM_UDID=$udid" >> "$GITHUB_ENV"
