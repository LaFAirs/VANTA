#!/usr/bin/env python3
"""Prepare release notes skeleton for a tag. Usage: prepare-release.py --tag 1.0.0"""
import argparse, datetime, pathlib
p = argparse.ArgumentParser()
p.add_argument("--tag", required=True)
a = p.parse_args()
out = pathlib.Path("RELEASE_NOTES.md")
out.write_text(
    f"# VANTA {a.tag} — {datetime.date.today().isoformat()}\n\n"
    "## Added\n- \n\n## Improved\n- \n\n## Fixed\n- \n\n"
    "## Security\n- \n\n## Known Issues\n"
    "- On-device install requires a valid signing identity; otherwise VANTA reports the reason explicitly.\n",
    encoding="utf-8",
)
print(f"wrote {out}")
