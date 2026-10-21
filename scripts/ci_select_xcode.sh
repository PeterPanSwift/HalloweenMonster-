#!/usr/bin/env bash
# Selects the Xcode used for the build. iPhone Duo needs the Xcode 27.1 release:
# on the xcode-27 image, Xcode_27.2*.app is a beta whose iOS 27.2 runtime has no Duo support.
set -euo pipefail

XCODE_VERSION="${XCODE_VERSION:-27.1}"

ls -d /Applications/Xcode*.app || true

xcode="/Applications/Xcode_${XCODE_VERSION}.app"
if [[ ! -d "$xcode" ]]; then
  echo "::error::$xcode not found on this runner"
  exit 1
fi

echo "Selecting $xcode"
sudo xcode-select -s "$xcode/Contents/Developer"
xcodebuild -version
echo "DEVELOPER_DIR=$xcode/Contents/Developer" >> "$GITHUB_ENV"
