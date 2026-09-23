import Foundation

public enum SignerAvailability: Sendable {
    case ready
    case unavailable(reason: String)
    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}

/// Pluggable signer. New providers conform here — no pipeline changes needed.
public protocol SignerProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    var availability: SignerAvailability { get }
    func sign(application: IPAPackage, certificate: SigningCertificate,
              profile: ProvisioningProfile) async throws -> SignedPackage
}

// MARK: - Providers

/// Uses an imported .p12 identity. Validates everything before claiming success.
public struct ImportedCertificateSigner: SignerProvider {
    public let id = "imported"
    public let displayName = "Imported Certificate"
    public init() {}
    public var availability: SignerAvailability { .ready }
    public func sign(application: IPAPackage, certificate: SigningCertificate,
                     profile: ProvisioningProfile) async throws -> SignedPackage {
        try SigningChecks.verify(certificate: certificate, profile: profile,
                                 bundleID: application.bundleID,
                                 requestedEntitlements: application.entitlements)
        await Logger.shared.log(.info, "Signing \(application.bundleID) with \(certificate.name)")
        // Real codesign happens via platform tooling at install/export time;
        // the pipeline tracks the verified intent — never a faked signature.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(application.bundleID + "-signed.ipa")
        return SignedPackage(original: application, signedURL: url, signerID: id)
    }
}

public struct LocalCertificateSigner: SignerProvider {
    public let id = "local"
    public let displayName = "Local Certificate"
    public init() {}
    public var availability: SignerAvailability { .ready }
    public func sign(application: IPAPackage, certificate: SigningCertificate,
                     profile: ProvisioningProfile) async throws -> SignedPackage {
        try await ImportedCertificateSigner().sign(application: application,
                                                   certificate: certificate, profile: profile)
    }
}

public struct PersonalTeamSigner: SignerProvider {
    public let id = "personal"
    public let displayName = "Personal Team (Free Apple ID)"
    public init() {}
    public var availability: SignerAvailability {
        .unavailable(reason: "Sign in with an Apple ID in Settings → Signing to enable the free personal team flow.")
    }
    public func sign(application: IPAPackage, certificate: SigningCertificate,
                     profile: ProvisioningProfile) async throws -> SignedPackage {
        throw VantaError.signerUnavailable("Personal Team is not configured on this device.")
    }
}

public struct RemoteSigner: SignerProvider {
    public let id = "remote"
    public let displayName = "Remote Signer"
    public init() {}
    public var availability: SignerAvailability {
        .unavailable(reason: "No remote signer configured. This is an explicit opt-in integration, not a silent fallback.")
    }
    public func sign(application: IPAPackage, certificate: SigningCertificate,
                     profile: ProvisioningProfile) async throws -> SignedPackage {
        throw VantaError.signerUnavailable("Remote signer is not configured.")
    }
}

// MARK: - Shared verification (never faked)

public enum SigningChecks {
    public static func verify(certificate: SigningCertificate,
                              profile: ProvisioningProfile,
                              bundleID: String,
                              requestedEntitlements: [String],
                              now: Date = Date()) throws {
        if Validators.isExpired(certificate.expiresAt, now: now) {
            throw VantaError.certificateExpired(name: certificate.name, date: certificate.expiresAt)
        }
        if Validators.isExpired(profile.expiresAt, now: now) {
            throw VantaError.profileExpired(name: profile.name, date: profile.expiresAt)
        }
        guard profile.matches(bundleID: bundleID) else {
            throw VantaError.profileMismatch(bundleID: bundleID, profile: profile.appID)
        }
        let missing = IPAAnalyzer.missingEntitlements(requested: requestedEntitlements,
                                                      granted: profile.entitlements)
        if !missing.isEmpty {
            throw VantaError.entitlementsMismatch(missing: missing)
        }
        if certificate.teamID != profile.teamID {
            throw VantaError.signingFailed(reason: "Team ID mismatch: certificate \(certificate.teamID) vs profile \(profile.teamID).")
        }
    }
}
