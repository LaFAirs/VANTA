# VANTA Signing

## Pipeline

```
IPA → Extract → Analyze → Certificate → Profile → BundleID check
  → Entitlements check → Sign → Repackage → Verify → Install
```

Implemented by `SigningPipeline` (`Vanta/Signing/SigningPipeline.swift`) over
the `SignerProvider` protocol:

```swift
public protocol SignerProvider {
    var id: String { get }
    var displayName: String { get }
    var availability: SignerAvailability { get }
    func sign(application: IPAPackage, certificate: SigningCertificate,
              profile: ProvisioningProfile) async throws -> SignedPackage
}
```

Providers: `LocalCertificateSigner` (real validation + `codesign`-ready hook),
`PersonalTeamSigner` (free Apple ID flow — availability-gated), 
`ImportedCertificateSigner`, `RemoteSigner` (explicit opt-in stub that refuses
without configuration — never fakes).

## What is *actually* verified

- Certificate: DER parse, expiry, `SecPolicy` trust evaluation where available
- Provisioning profile: plist parse, `application-identifier`, team ID, expiry,
  entitlements subset check
- Bundle ID: exact or wildcard match against profile
- Entitlements: requested ⊆ granted, else `entitlementsMismatch` with diff
- Signature (post-sign): `codesign --verify`-equivalent check on macOS tooling;
  on iOS, verify metadata consistency and report limits honestly

## Error style (example)

> **Signing failed**
> The selected provisioning profile does not match this Bundle Identifier.
> Bundle ID: `com.example.app` · Profile: `com.other.app`
> Actions: [Choose another profile]

See `Core/VantaError.swift` — every error has title, reason, and remedy.
