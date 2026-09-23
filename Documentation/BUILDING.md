# Building VANTA — Windows-first guide

```
Windows 11
  ↓  git clone / edit (VS Code)
GitHub
  ↓  push / PR
GitHub Actions
  ↓  macOS runner (macos-15) + Xcode 16
XcodeGen → SwiftLint → xcodebuild (simulator)
  ↓
Artifact / Release asset
```

## What works on Windows 11

- ✅ Full source editing (Swift files are plain text)
- ✅ Git, GitHub PRs, issues, releases, code review
- ✅ Repo hygiene checks: `python Scripts/validate-repo.py`
- ✅ Workflow YAML validation
- ✅ Documentation, CHANGELOG, versioning
- ✅ Triggering CI builds + downloading CI artifacts
- ✅ SwiftLint *rule review* (but not execution — SwiftLint needs macOS/Linux)

## What requires macOS + Xcode

- ❌ Compiling SwiftUI to `.app` / `.ipa` (`xcodebuild`, `codesign`)
- ❌ Running the iOS Simulator / unit tests on Apple SDKs
- ❌ Real code-signing (`codesign`, provisioning, notarization)
- ❌ Exporting/uploading to TestFlight / App Store Connect

> VANTA never pretends Windows can replace Xcode signing. CI makes the
> boundary explicit: the `validate-windows` job runs anywhere; the
> `build-macos` / `test-macos` jobs require `runs-on: macos-15`.

## Recommended Windows setup

1. Install Git + VS Code (+ Swift extension for syntax only).
2. Install Python 3.11+ (for `Scripts/*.py`).
3. Clone and validate:
   ```powershell
   git clone https://github.com/LaFAirs/VANTA.git
   cd VANTA
   python Scripts/validate-repo.py
   ```
4. Work on a branch, push, open a draft PR — CI builds on macOS automatically.

## First real build (via CI, no Mac needed)

1. Push to `main` or open a PR.
2. Open *Actions → Build* — the `build-macos` job generates the Xcode project
   (`xcodegen generate`) and builds for simulator with `CODE_SIGNING_ALLOWED=NO`.
3. Download logs/artifacts from the run.

## Building locally on a Mac

```bash
brew install xcodegen swiftlint
xcodegen generate
open Vanta.xcodeproj
# or headless:
xcodebuild -scheme Vanta -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild test -scheme Vanta -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Signing a release IPA (maintainers only)

Secrets live in GitHub *Actions Secrets*, never in the repo:

- `APPLE_CERTIFICATE` (base64 `.p12`)
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_PROVISIONING_PROFILE` (base64 `.mobileprovision`)
- `APPLE_TEAM_ID`

`release.yml` imports them into a throwaway keychain only when present;
otherwise it ships unsigned notes + checksums and says so in the log.

## From source to IPA (release flow)

```text
Windows
  ↓  git tag v1.0.0 + git push origin v1.0.0
GitHub
  ↓  Release workflow starts (tag trigger)
macOS Runner
  ↓  XcodeGen → tests → archive → export/package
IPA validation + SHA256SUMS.txt
  ↓
GitHub Release with VANTA.ipa + SHA256SUMS.txt
```

No local Xcode needed — tagging from Windows is enough. Full details,
signing modes, and honest limitations: [`RELEASING.md`](RELEASING.md).
