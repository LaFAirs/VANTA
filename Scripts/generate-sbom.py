#!/usr/bin/env python3
"""Generate an honest CycloneDX SBOM for the VANTA release asset.

VANTA currently has ZERO external Swift package dependencies (see project.yml:
packages: {}), so the SBOM truthfully lists zero components. It records the
application itself (name, version, bundle id, SHA-256) plus build metadata.
If dependencies are ever added, extend DEPENDENCIES from the resolved manifest
instead of hand-editing this file.

Usage: generate-sbom.py --version 1.0.0 --build 3 --bundle-id com.vanta.app \\
       --sha-file SHA256SUMS.txt --output SBOM.json
"""
import argparse
import datetime
import hashlib
import json
import pathlib
import sys

p = argparse.ArgumentParser()
p.add_argument("--version", required=True)
p.add_argument("--build", required=True)
p.add_argument("--bundle-id", required=True)
p.add_argument("--sha-file", required=True)
p.add_argument("--output", default="SBOM.json")
a = p.parse_args()

sha_path = pathlib.Path(a.sha_file)
if not sha_path.is_file():
    sys.exit(f"sha file not found: {a.sha_file}")
sha = sha_path.read_text(encoding="utf-8").strip().splitlines()[0].split()[0]

# No Package.swift / Package.resolved in this repo (XcodeGen, no SPM deps).
# Verified by validate-repo.py keeping Scripts/ honest; do not invent entries.
resolved = pathlib.Path("Package.resolved")
dependencies: list[dict] = []
if resolved.is_file():
    sys.exit("Package.resolved exists but SBOM extraction is not implemented — refusing to guess.")

sbom = {
    "bomFormat": "CycloneDX",
    "specVersion": "1.6",
    "version": 1,
    "metadata": {
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "component": {
            "type": "application",
            "name": "VANTA",
            "version": f"{a.version} ({a.build})",
            "bom-ref": f"pkg:generic/vanta@v{a.version}?build={a.build}",
            "properties": [
                {"name": "vanta:bundle-id", "value": a.bundle_id},
                {"name": "vanta:ipa-sha256", "value": sha},
            ],
            "hashes": [{"alg": "SHA-256", "content": sha}],
        },
    },
    "components": dependencies,
}
out = pathlib.Path(a.output)
out.write_text(json.dumps(sbom, indent=2) + "\n", encoding="utf-8")
digest = hashlib.sha256(out.read_bytes()).hexdigest()
print(f"wrote {out} ({len(dependencies)} vendored dependencies, sha256={digest})")
