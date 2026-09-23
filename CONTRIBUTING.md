# Contributing to VANTA

Thanks for your interest in VANTA — Advanced iOS & iPadOS Sideloading.

## Ground rules

1. **No clones.** Do not submit code, assets, or branding copied from Scarlet,
   KSign, SideStore, or any proprietary app. Only original work or code with a
   compatible open-source license (with attribution).
2. **No secrets.** Never commit `.p12`, `.mobileprovision`, tokens, or passwords.
   CI secrets live in GitHub Actions Secrets only.
3. **No fake features.** If something cannot run in an environment, surface
   `Coming Soon` / `Not available in this environment` — never fake signing,
   validation, or installation success.
4. **Windows-first workflow.** Most contributors work on Windows: keep all
   validation possible in CI (GitHub Actions + macOS runner + Xcode).

## Workflow

1. Fork → feature branch (`feat/<scope>`, `fix/<scope>`, `docs/<scope>`).
2. Follow the architecture in `Documentation/ARCHITECTURE.md`.
3. Add/extend tests in `VantaTests/` — every parser, validator, and signer
   change needs assertions (no fake tests).
4. Run before pushing (on macOS, or via CI from Windows):
   ```bash
   xcodegen generate
   xcodebuild -scheme Vanta -destination 'platform=iOS Simulator,name=iPhone 16' build
   xcodebuild test -scheme Vanta -destination 'platform=iOS Simulator,name=iPhone 16'
   ```
   From Windows, pushing to a draft PR triggers the same checks in CI.
5. Open a PR using the PR template. Link issues. Keep diffs focused.

## Code style

- Swift 5.9+, SwiftUI, `async/await`, actors where shared mutable state exists.
- SwiftLint style: 120 col, sorted imports, no force-unwraps in production paths
  (use `guard` + typed `VantaError`).
- Accessibility: Dynamic Type, VoiceOver labels, sufficient contrast, Reduce Motion.

## Commit style

Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`, `ci:`.
