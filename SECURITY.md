# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.0.x   | ✅        |
| < 1.0   | ❌        |

## Responsible Disclosure

**Do not open a public issue for vulnerabilities.**

Report security issues privately:

1. Open a [GitHub Security Advisory](https://docs.github.com/en/code-security/security-advisories) on this repository, **or**
2. Contact the maintainers via the email listed in the repository profile / `DeveloperConfig.swift`.

Please include:

- Affected version / commit
- Steps to reproduce
- Impact assessment
- Suggested mitigation (if any)

We aim to acknowledge reports within **72 hours** and provide a fix timeline within **7 days**.

## Rules VANTA enforces

- No private keys (`.p12`, `.key`, `.p8`), certificates (`.cer`), provisioning profiles
  (`.mobileprovision`), or Apple API keys are ever committed. See `.gitignore`.
- No hardcoded tokens, passwords, or signing secrets in Swift sources.
- CI signing uses **GitHub Actions Secrets only**:
  `APPLE_CERTIFICATE`, `APPLE_CERTIFICATE_PASSWORD`,
  `APPLE_PROVISIONING_PROFILE`, `APPLE_TEAM_ID`.
- App secrets on device live in the **Keychain**; backups encrypt sensitive fields
  with AES-GCM (CryptoKit). Plaintext export of private keys is refused by design.
- Repository downloads over plain `http://` trigger an explicit warning and require
  user confirmation. `https://` + validated manifests are the default.

## Out of scope

- Bypassing Apple code-signing / DRM.
- Distributing cracked IPAs or stolen certificates.
- Social-engineering reports without a technical finding.
