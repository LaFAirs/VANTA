# Scripts

Windows/macOS/Linux-safe helpers (Python 3.11+, no Xcode required).

| Script | Purpose |
| ------ | ------- |
| `validate-repo.py` | Fails on committed secrets (`.p12`, `.mobileprovision`, `Secrets.swift`), missing docs/dirs. Runs in CI (`validate-windows`) and locally: `python Scripts/validate-repo.py` |
| `prepare-release.py --tag X.Y.Z` | Writes `RELEASE_NOTES.md` skeleton for a published release (used by `release.yml`) |
