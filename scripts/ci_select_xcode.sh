#!/usr/bin/env bash
# Selects the newest Xcode 27.x on the runner. iPhone Duo needs Xcode 27.1 or later.
set -euo pipefail

ls -d /Applications/Xcode*.app || true

candidates=$(ls -d /Applications/Xcode_27*.app 2>/dev/null | grep -vi beta || true)
if [[ -z "$candidates" ]]; then
  candidates=$(ls -d /Applications/Xcode_27*.app 2>/dev/null || true)
fi
if [[ -z "$candidates" ]]; then
  echo "::error::No Xcode 27 found on this runner"
  exit 1
fi

# Sort by version number (Xcode_27.1.app > Xcode_27.0.app) and take the newest.
xcode=$(echo "$candidates" | sed -E 's|.*/Xcode_([0-9.]+)[^/]*\.app|\1 &|' | sort -V | tail -n 1 | cut -d' ' -f2-)
echo "Selecting $xcode"
sudo xcode-select -s "$xcode/Contents/Developer"
xcodebuild -version
echo "DEVELOPER_DIR=$xcode/Contents/Developer" >> "$GITHUB_ENV"
