#!/usr/bin/env bash
# VANTA IPA validation (runs on the macOS CI runner, after export).
# Usage: validate-ipa.sh VANTA.ipa --mode unsigned|signed --expected-version 1.0.0
#
# Fails the workflow on ANY mismatch. Never prints a false success.
set -euo pipefail

IPA="${1:?usage: validate-ipa.sh <file.ipa> --mode <unsigned|signed> --expected-version <x.y.z>}"
shift
MODE="unsigned"
EXPECTED=""
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE="${2:?}"; shift 2 ;;
    --expected-version) EXPECTED="${2:?}"; shift 2 ;;
    *) echo "::error::Unknown argument: $1"; exit 1 ;;
  esac
done

fail() { echo "::error::$1"; exit 1; }

[ -f "$IPA" ] || fail "IPA not found: $IPA"
[ -s "$IPA" ] || fail "IPA is empty: $IPA"
unzip -t "$IPA" >/dev/null 2>&1 || fail "$IPA is not a valid ZIP archive."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
unzip -q "$IPA" -d "$WORK" || fail "Cannot unzip $IPA."

APPS=( "$WORK"/Payload/*.app )
[ ${#APPS[@]} -eq 1 ] || fail "Expected exactly one Payload/*.app, found ${#APPS[@]}."
APP="${APPS[0]}"
INFO="$APP/Info.plist"
[ -f "$INFO" ] || fail "No Info.plist inside $(basename "$APP")."

BID="$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$INFO" 2>/dev/null)" \
  || fail "CFBundleIdentifier missing in app Info.plist."
VER="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO" 2>/dev/null)" \
  || fail "CFBundleShortVersionString missing in app Info.plist."
BUILD="$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO" 2>/dev/null)" \
  || fail "CFBundleVersion missing in app Info.plist."

[ -n "$EXPECTED" ] && [ "$VER" != "$EXPECTED" ] \
  && fail "Version mismatch: IPA is $VER but release tag expects $EXPECTED."

SIZE="$(wc -c < "$IPA" | tr -d ' ')"

if [ "$MODE" = "signed" ]; then
  [ -d "$APP/_CodeSignature" ] || fail "Signed mode but no _CodeSignature in app bundle."
  [ -f "$APP/embedded.mobileprovision" ] || fail "Signed mode but no embedded.mobileprovision."
  codesign -v "$APP" 2>/dev/null || fail "codesign verification failed."
  TEAM="$(codesign -dvv "$APP" 2>&1 | sed -n 's/^TeamIdentifier=//p' | head -n1)"
  [ -n "$TEAM" ] || fail "No TeamIdentifier in code signature."
  echo "signing=signed (TeamIdentifier present, signature verifies)"
else
  echo "signing=unsigned (no Apple signature — re-signing required before installing)"
fi

# Export facts for later steps (release notes). No secrets involved.
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "bundle_id=$BID"
    echo "app_version=$VER"
    echo "app_build=$BUILD"
    echo "ipa_size=$SIZE"
  } >> "$GITHUB_OUTPUT"
fi

echo "::notice::IPA validation passed: $BID v$VER ($BUILD), ${SIZE} bytes, mode=$MODE"
