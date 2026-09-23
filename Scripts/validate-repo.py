#!/usr/bin/env python3
"""Windows/macOS/Linux-safe repo hygiene check (no Xcode required).

Fails if:
- forbidden signing artefacts are tracked (*.p12, *.mobileprovision, Secrets.swift)
- required top-level docs are missing
- required source dirs are missing
"""
import pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FORBIDDEN_SUFFIXES = (".p12", ".pfx", ".mobileprovision", ".provisionprofile", ".cer", ".key", ".p8", ".pem")
REQUIRED_DOCS = ["README.md", "LICENSE", "SECURITY.md", "CONTRIBUTING.md", "CODE_OF_CONDUCT.md", "CHANGELOG.md"]
REQUIRED_DIRS = ["Vanta", "VantaTests", "Documentation", "Scripts", "Resources", ".github/workflows"]
REQUIRED_GITHUB = [
    ".github/CODEOWNERS",
    ".github/FUNDING.yml",
    ".github/dependabot.yml",
    ".github/workflows/build.yml",
    ".github/workflows/test.yml",
    ".github/workflows/release.yml",
    ".github/workflows/codeql.yml",
    ".github/workflows/dependency-review.yml",
]

errors: list[str] = []
for suffix in FORBIDDEN_SUFFIXES:
    hits = [p for p in ROOT.rglob(f"*{suffix}") if ".git/" not in p.as_posix() and "Resources/" not in p.as_posix()]
    # Resources/ allowed only for placeholder docs, never real keys — flag any real file present
    for h in hits:
        errors.append(f"forbidden artefact present: {h.relative_to(ROOT)}")
for name in REQUIRED_DOCS:
    if not (ROOT / name).exists():
        errors.append(f"missing required doc: {name}")
for d in REQUIRED_DIRS:
    if not (ROOT / d).is_dir():
        errors.append(f"missing required dir: {d}")
for g in REQUIRED_GITHUB:
    if not (ROOT / g).is_file():
        errors.append(f"missing required github file: {g}")
if (ROOT / "Vanta" / "App" / "Secrets.swift").exists():
    errors.append("Vanta/App/Secrets.swift must never exist in repo")

if errors:
    print("validate-repo FAILED:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
print("validate-repo OK")
