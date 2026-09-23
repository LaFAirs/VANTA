#!/usr/bin/env bash
# Ensures a bootable iOS Simulator device exists on the runner and exports
# SIM_DESTINATION (e.g. "platform=iOS Simulator,id=<UDID>") to $GITHUB_ENV.
# macOS images / Xcode versions vary; never assume "iPhone 16" exists.
set -euo pipefail

pick_udid() {
    xcrun simctl list devices -j | python3 -c '
import json, sys
try:
    devs = json.load(sys.stdin)["devices"]
except Exception:
    devs = {}
found = ""
for runtime, entries in devs.items():
    for d in entries or []:
        if d.get("isAvailable") and "iPhone" in str(d.get("name", "")):
            found = d.get("udid", "")
            break
    if found:
        break
print(found)
'
}

UDID="$(pick_udid)"
if [ -z "$UDID" ]; then
    echo "No available iPhone simulator — looking for a runtime."
    RUNTIME="$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
try:
    rs = json.load(sys.stdin)["runtimes"]
except Exception:
    rs = []
ios = [r for r in rs if r.get("platform") == "iOS" and r.get("isAvailable", True)]
ios.sort(key=lambda r: r.get("version", ""))
print(ios[-1]["identifier"] if ios else "")
')"
    if [ -z "$RUNTIME" ]; then
        echo "No iOS runtime installed — downloading the iOS platform (slow, one-off)."
        xcodebuild -downloadPlatform iOS
        RUNTIME="$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
rs = json.load(sys.stdin)["runtimes"]
ios = [r for r in rs if r.get("platform") == "iOS" and r.get("isAvailable", True)]
ios.sort(key=lambda r: r.get("version", ""))
print(ios[-1]["identifier"] if ios else "")
')"
        [ -n "$RUNTIME" ] || { echo "::error::No iOS simulator runtime available even after download."; exit 1; }
    fi
    DEVICETYPE="$(xcrun simctl list devicetypes -j | python3 -c '
import json, sys
dts = json.load(sys.stdin)["devicetypes"]
names = {d["name"]: d["identifier"] for d in dts}
if "iPhone 16" in names:
    print(names["iPhone 16"])
else:
    phones = [v for k, v in names.items() if "iPhone" in k]
    print(phones[0] if phones else "")
')"
    [ -n "$DEVICETYPE" ] || { echo "::error::No iPhone device type available."; exit 1; }
    echo "Creating simulator device ($DEVICETYPE on $RUNTIME)."
    UDID="$(xcrun simctl create "VANTA-CI" "$DEVICETYPE" "$RUNTIME")"
fi

echo "SIM_DESTINATION=platform=iOS Simulator,id=$UDID" >> "${GITHUB_ENV:?GITHUB_ENV is required}"
echo "Using simulator destination: platform=iOS Simulator,id=$UDID"
xcrun simctl list devices | grep -F "$UDID" || true
