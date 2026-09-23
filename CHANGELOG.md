# Changelog

All notable changes to VANTA are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-09-23

### Added
- Real IPA release pipeline (`release.yml`: tag trigger → XcodeGen → tests →
  archive → export/package → validation → SHA256 → GitHub Release assets),
  with automatic signed/unsigned modes and `Documentation/RELEASING.md`
- `Scripts/validate-ipa.sh` (gating IPA validation) and
  `Scripts/generate-release-notes.py` (honest notes with real SHA + signing status)
- Initial VANTA repository structure
- SwiftUI design system (VantaDS: dark `#05070A`, cards `#101722`, electric blue accent)
- Tab (iPhone) / Sidebar (iPad) navigation
- Home dashboard (device, certificates, refresh, activity)
- IPA Manager: import pipeline (Analyze → Sign → Verify → Install) with live progress
- IPA Analyzer: metadata, architectures, entitlements, signing info
- Certificate Center: .p12 / .mobileprovision import, inspection, validation
- Modular Signer architecture (`SignerProvider` protocol)
- Repository system with validation + Discover feed
- Refresh system (honest expiry messaging, no fake promises)
- Backup & Restore (Keychain-backed, encrypted secrets — never plaintext)
- File Manager, Log system, Settings, About with GitHub integration
- GitHub Actions: build / test / release pipelines
- Documentation: BUILDING (Windows-first), SIGNING, ARCHITECTURE, SECURITY,
  RELEASING (real IPA pipeline)

### Known Issues
- Unsigned CI builds must be re-signed before installing (see RELEASING.md).
- On-device IPA installation requires a valid Apple signing identity; without one,
  VANTA shows `Not available in this environment` instead of faking success.
- Building the `.ipa` requires macOS + Xcode (see `Documentation/BUILDING.md`).
