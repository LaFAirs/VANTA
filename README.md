<div align="center">

<!-- VANTA logo: black rounded square, electric-blue geometric V (see Resources/AppIcon/) -->

# VANTA

**Advanced iOS & iPadOS Sideloading.**

</div>

[![Build](https://github.com/dbudakli1402-collab/VANTA/actions/workflows/build.yml/badge.svg)](https://github.com/dbudakli1402-collab/VANTA/actions/workflows/build.yml)
[![Tests](https://github.com/dbudakli1402-collab/VANTA/actions/workflows/test.yml/badge.svg)](https://github.com/dbudakli1402-collab/VANTA/actions/workflows/test.yml)
[![Release](https://github.com/dbudakli1402-collab/VANTA/actions/workflows/release.yml/badge.svg)](https://github.com/dbudakli1402-collab/VANTA/actions/workflows/release.yml)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://www.swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Badges resolve once the repo is public and the workflows have run at least once.

VANTA is an independent, open-source sideloading manager for iOS & iPadOS —
inspired by the *capabilities* of tools like Scarlet, KSign, and SideStore,
but with its **own UI, own architecture, and own branding**. No copied code,
no proprietary assets, no cloned logos.

## Screenshots

Screenshots live in [`Documentation/Screenshots/`](Documentation/Screenshots/).
Placeholders until the first TestFlight / release build:

| Home | Apps | Signing | Certificates | Discover | About |
| ---- | ---- | ------- | ------------ | -------- | ----- |
| ![Home](Documentation/Screenshots/home.png) | ![Apps](Documentation/Screenshots/apps.png) | ![Signing](Documentation/Screenshots/signing.png) | ![Certificates](Documentation/Screenshots/certificates.png) | ![Discover](Documentation/Screenshots/discover.png) | ![About](Documentation/Screenshots/about.png) |

## Features

- **Home dashboard** — device, iOS version, VANTA version, managed apps, active certificates, upcoming refreshes, activity feed
- **IPA Manager** — Files / Share Sheet / Drag & Drop (iPad) / URL import, queue + bulk install
- **IPA Analyzer** — name, bundle ID, version, build, min iOS, architectures, entitlements, frameworks, signing info
- **Certificate Center** — `.p12` / `.mobileprovision` import, inspect, test, remove
- **Modular Signer system** — `SignerProvider` protocol (`LocalCertificateSigner`, `PersonalTeamSigner`, `ImportedCertificateSigner`, `RemoteSigner` stub)
- **Honest signing pipeline** — Extract → Analyze → Certificate → Profile → Bundle ID → Entitlements → Sign → Repackage → Verify → Install, with per-step logs
- **Repository system** — validated JSON manifests, `https` by default, `http` warns
- **Discover** — per-source app cards, version, changelog, always-visible source
- **Refresh system** — honest expiry messaging, per-app + bulk refresh
- **Backup & Restore** — Keychain-backed, AES-GCM encrypted secrets
- **File Manager, Logs, Settings, About/GitHub integration**

> VANTA never fakes signing, validation, or installation. Unavailable steps show
> `Coming Soon` or `Not available in this environment` with a reason.

## Installation

**Latest release:** [GitHub Releases](https://github.com/dbudakli1402-collab/VANTA/releases)
([latest build](https://github.com/dbudakli1402-collab/VANTA/releases/latest)).

Every release attaches:

- **VANTA.ipa** — the real CI-built app package
- **SHA256SUMS.txt** — checksum computed from that exact IPA
- **Signing status** — stated in the release notes (no guessing)

Verify after download:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

Then:

1. **Signed releases:** sideload with your preferred tool, then trust the
   profile under *Settings → General → VPN & Device Management*.
2. **Unsigned releases:** re-sign the IPA with your own Apple certificate /
   provisioning profile first — unsigned IPAs cannot be installed as-is
   (see [`Documentation/RELEASING.md`](Documentation/RELEASING.md)).

Until the first release pipeline has run, no IPA exists yet — anything else
would be a fake download link, so there is none.

## Supported Devices

- iPhone, iOS 17.0+
- iPad, iPadOS 17.0+ (sidebar layout, Split View, drag & drop)

## Signing Architecture

See [`Documentation/SIGNING.md`](Documentation/SIGNING.md) and
[`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md).

```
IPA → Extract → Analyze → Certificate → Profile → BundleID check
  → Entitlements check → Sign → Repackage → Verify → Install
```

Every step reports status + progress + logs + typed errors (`VantaError`).

## Certificate Management

`.p12` + `.mobileprovision` are parsed and cross-checked (Team ID, bundle ID,
expiry, entitlements). Mismatches produce actionable errors, e.g.
*“The selected provisioning profile does not match this Bundle Identifier.”*

## Repository System

```json
{
  "name": "Example Repo",
  "identifier": "com.example.repo",
  "apps": [{
    "name": "Example",
    "bundleIdentifier": "com.example.app",
    "version": "1.2.3",
    "downloadURL": "https://example.com/app.ipa",
    "iconURL": "https://example.com/icon.png",
    "developer": "Example",
    "localizedDescription": "…",
    "versionDate": "2026-09-01T00:00:00Z"
  }]
}
```

Validated client-side (`RepositoryValidator`): https-required (or explicit http
acknowledgement), version/date sanity, icon + IPA URL checks.

## Development

Windows-first (see [`Documentation/BUILDING.md`](Documentation/BUILDING.md)):

```powershell
git clone https://github.com/dbudakli1402-collab/VANTA.git
cd VANTA
# edit in VS Code / any editor on Windows, push → CI builds on macOS runner
```

On macOS with Xcode 16+:

```bash
brew install xcodegen swiftlint
xcodegen generate
open Vanta.xcodeproj
xcodebuild -scheme Vanta -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild test -scheme Vanta -destination 'platform=iOS Simulator,name=iPhone 16'
```

## GitHub Actions

| Workflow | Trigger | Does |
| -------- | ------- | ---- |
| `build.yml` | push / PR | XcodeGen → lint → simulator build |
| `test.yml` | push / PR, nightly | unit + parser + security tests |
| `release.yml` | published release | tests → archive → checksums → assets |

Apple signing credentials come **only** from Actions Secrets
(`APPLE_CERTIFICATE`, `APPLE_CERTIFICATE_PASSWORD`,
`APPLE_PROVISIONING_PROFILE`, `APPLE_TEAM_ID`) — never committed.

## Security

See [`SECURITY.md`](SECURITY.md). Keychain + AES-GCM, `.gitignore` blocks
`*.p12` / `*.mobileprovision` / `Secrets.swift`, responsible disclosure only.

## FAQ

**Does VANTA work on Windows?**
You can develop, edit, and drive CI from Windows. Compiling + signing an iOS
`.ipa` requires macOS + Xcode (local Mac or GitHub macOS runner). No workaround
is faked — see `Documentation/BUILDING.md`.

**Is it a Scarlet / SideStore clone?**
No. Independent UI, architecture, and branding. Comparable *capability scope*
(IPA import, signing, repos, refresh), original implementation.

**Why does refresh say “unavailable”?**
Without a valid signing identity / network / Apple backend reachability, VANTA
tells you exactly why instead of inventing an expiry date.

## Roadmap

- [ ] On-device `ldid`-style flow research (honest capability matrix)
- [ ] Anisette / refresh automation without fake promises
- [ ] Tweak injection metadata display
- [ ] Localization (de, en first)
- [ ] tvOS / visionOS evaluation

## License

MIT — see [LICENSE](LICENSE).
