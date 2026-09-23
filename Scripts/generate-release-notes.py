#!/usr/bin/env python3
"""Generate honest VANTA release notes from real build facts.

Usage:
  generate-release-notes.py --tag v1.0.0 --version 1.0.0 --build 5 \
      --signing-mode unsigned|signed --sha-file SHA256SUMS.txt \
      --bundle-id com.vanta.app [--repo dbudakli1402-collab/VANTA]

Every value in the notes comes from the actual pipeline (tag, validation,
checksum file). The signing status always reflects the real mode.
"""
import argparse
import datetime
import pathlib
import sys

FEATURES = [
    "IPA management (import, queue, bulk install)",
    "IPA analyzer (metadata, architectures, entitlements)",
    "Certificate Center (.p12 / .mobileprovision)",
    "Modular signer architecture with honest validation",
    "Repository system + Discover feed",
    "Refresh center, backup & restore, file manager, logs",
    "GitHub-integrated About page",
]

p = argparse.ArgumentParser()
p.add_argument("--tag", required=True)
p.add_argument("--version", required=True)
p.add_argument("--build", required=True)
p.add_argument("--signing-mode", required=True, choices=["unsigned", "signed"])
p.add_argument("--sha-file", required=True)
p.add_argument("--bundle-id", required=True)
p.add_argument("--repo", default="dbudakli1402-collab/VANTA")
a = p.parse_args()

sha_path = pathlib.Path(a.sha_file)
if not sha_path.is_file():
    sys.exit(f"sha file not found: {a.sha_file}")
sha_line = sha_path.read_text(encoding="utf-8").strip().splitlines()[0]
sha = sha_line.split()[0]
if len(sha) != 64 or any(c not in "0123456789abcdef" for c in sha):
    sys.exit(f"not a valid SHA-256 line: {sha_line!r}")

if a.signing_mode == "signed":
    signing_type = "Signed"
    signing_detail = (
        "Signed with the maintainer's Apple development identity "
        "via GitHub Actions Secrets. Installable on registered devices; "
        "trust the profile under Settings → General → VPN & Device Management."
    )
else:
    signing_type = "Unsigned"
    signing_detail = (
        "Built from source WITHOUT an Apple signature "
        "(no signing credentials configured in CI). "
        "This IPA is structurally valid but CANNOT be installed as-is — "
        "re-sign it with your own certificate / provisioning profile first "
        "(see Documentation/RELEASING.md). VANTA never fakes a signature."
    )

today = datetime.date.today().isoformat()
notes = f"""# VANTA {a.tag} — {today}

## Highlights

"""
for f in FEATURES:
    notes += f"- {f}\n"
notes += f"""
## Downloads

### VANTA.ipa

- Type: **{signing_type}**
- Bundle ID: `{a.bundle_id}`
- Version: `{a.version}` (build `{a.build}`)
- SHA-256: `{sha}`

Verify after download:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

## Requirements

- iPhone with iOS 17.0+ or iPad with iPadOS 17.0+
- For unsigned builds: your own Apple signing identity to re-sign

## Important

{signing_detail}

## Known Issues

- On-device installation requires a valid signing identity; VANTA reports
  the exact reason instead of inventing success.
- Screenshots in the README are placeholders until device captures exist.
"""
pathlib.Path("RELEASE_NOTES.md").write_text(notes, encoding="utf-8")
print("wrote RELEASE_NOTES.md")
