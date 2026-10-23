#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# An explicit destination can be passed for reproducing a particular device run.
if [[ -z "${SIMULATOR_ID:-}" ]]; then
  SIMULATOR_ID=$(xcrun simctl list devices available --json | python3 -c '
import json, re, sys
candidates = []
for runtime, devices in json.load(sys.stdin)["devices"].items():
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match:
        continue
    version = tuple(map(int, match.groups()))
    if version < (27, 0):
        continue
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            candidates.append((device.get("state") == "Booted", version, device["name"], device["udid"]))
if not candidates:
    sys.exit("No available iPhone simulator with iOS 27 or later. Install a runtime in Xcode Settings > Components.")
print(sorted(candidates, reverse=True)[0][3])
')
fi

DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-.build/DerivedData}
RESULT_BUNDLE_PATH=${RESULT_BUNDLE_PATH:-.build/TestResults-$(date +%Y%m%d-%H%M%S).xcresult}
mkdir -p "$(dirname "$RESULT_BUNDLE_PATH")"
xcodebuild -version
printf 'Testing simulator %s; result bundle: %s\n' "$SIMULATOR_ID" "$RESULT_BUNDLE_PATH"
xcodebuild test \
  -project BillFlow.xcodeproj \
  -scheme BillFlow \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -destination-timeout 60 \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -resultBundlePath "$RESULT_BUNDLE_PATH" \
  -only-testing:BillFlowTests \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
