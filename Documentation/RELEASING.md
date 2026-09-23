# Releasing VANTA — real IPA pipeline

```
git tag v1.0.0
  ↓  git push origin v1.0.0
GitHub Release workflow (macOS runner, Xcode)
  ↓  XcodeGen → tests → archive → export/package
IPA validation (structure, version, signature)
  ↓  SHA256SUMS.txt → release notes
GitHub Release v1.0.0
  ↓  Assets: VANTA.ipa + SHA256SUMS.txt
```

Trigger is **tag push only** (`v*`). Creating the GitHub Release inside the
workflow cannot loop: publishing a release does not push a tag.

## Versioning (single source of truth: the tag)

- Tag `v1.0.0` → `MARKETING_VERSION=1.0.0`, `CURRENT_PROJECT_VERSION=<run number>`,
  passed as `xcodebuild` overrides. `project.yml` keeps sane defaults (`1.0.0`/`100`)
  for local development.
- `Scripts/validate-ipa.sh` fails the workflow if the IPA's
  `CFBundleShortVersionString` differs from the tag version. No silent mismatch.

## Signing modes (automatic)

| | Unsigned / Build-only | Signed Release |
|---|---|---|
| Condition | signing secrets absent | `APPLE_CERTIFICATE`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_PROVISIONING_PROFILE`, `APPLE_TEAM_ID` all set |
| Archive | `CODE_SIGNING_ALLOWED=NO`, manual signing | automatic signing with `DEVELOPMENT_TEAM` |
| IPA | `Payload/*.app` zipped with `ditto` — structurally valid, **no signature** | `xcodebuild -exportArchive` with dynamically generated `ExportOptions.plist` |
| Installable as-is | **No** — re-sign first | Yes, on registered devices (see below) |

Secrets live **only** in GitHub Actions Secrets, are used via environment
variables, and are wiped afterwards (throwaway keychain deleted in an
`always()` step). Optional: `EXPORT_METHOD` secret (`development` default,
`ad-hoc`, or `app-store`) selects the export method — it must match how your
team/profiles are actually configured.

## Honest limitations (not bugs, documented on purpose)

1. **Unsigned IPAs cannot be installed on stock iOS.** Apple requires a valid
   signature. Re-sign with your own identity (Xcode, Apple Configurator, or
   any sideloading tool), then install.
2. **Development/ad-hoc signed IPAs only install on registered devices.**
   A public open-source project cannot ship a universally installable
   development-signed IPA — anyone claiming otherwise is faking it.
3. **App Store distribution** needs App Store Connect + review and is out of
   scope for this pipeline (`EXPORT_METHOD=app-store` is supported
   mechanically if you configure it).

## Release checklist (maintainer)

1. `CHANGELOG.md`: move entries from Unreleased to `[<version>]`, date it.
2. `git tag v<version> && git push origin v<version>`.
3. Watch *Actions → Release*: tests → archive → IPA → validation → checksums.
4. Open the published release, verify `VANTA.ipa` + `SHA256SUMS.txt` assets,
   verify `shasum -a 256 -c SHA256SUMS.txt` after download.
5. If anything fails: the workflow fails, **no release is published**.
   Fix, delete the tag if needed (`git push --delete origin v...` + local
   `git tag -d`), re-tag.
