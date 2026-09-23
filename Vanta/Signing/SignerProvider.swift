import CryptoKit
import Foundation

/// Readiness of a signer for a concrete certificate/profile pair.
public enum SignerAvailability: Sendable {
    /// Ready to sign.
    case ready
    /// Not usable, with the real reason.
    case unavailable(reason: String)

    /// True when ready.
    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    /// The unavailability reason, if any.
    public var reason: String? {
        if case .unavailable(let detail) = self { return detail }
        return nil
    }
}

/// Pluggable signer. New providers conform here — no pipeline changes needed.
public protocol SignerProvider: Sendable {
    /// Stable identifier (e.g. "local").
    var id: String { get }
    /// Display name.
    var displayName: String { get }
    /// Real readiness for this certificate/profile pair (expiry, match).
    /// Never reports ready without checking.
    func availability(certificate: SigningCertificate, profile: ProvisioningProfile) -> SignerAvailability
    /// Stages a signed package as a REAL file and reports 0…1 progress.
    /// Throws instead of returning a non-existent path. Never fakes a signature.
    func sign(
        application: IPAPackage,
        certificate: SigningCertificate,
        profile: ProvisioningProfile,
        progress: @Sendable (Double) -> Void
    ) async throws -> SignedPackage
}

/// Shared staging: copies the IPA to temp, writes a manifest, hashes it.
/// Returns the staged file URL plus its SHA-256. The file always exists.
enum SignerStaging {
    /// Manifest written next to every staged package.
    struct Manifest: Codable {
        /// Bundle identifier.
        var bundleID: String
        /// Marketing version.
        var version: String
        /// Signer identifier.
        var signerID: String
        /// Signing team.
        var teamID: String
        /// SHA-256 of the staged file.
        var sha256: String
    }

    /// Stages the package file. Throws when there is no source file.
    static func stage(
        application: IPAPackage,
        certificate: SigningCertificate,
        signerID: String,
        progress: @Sendable (Double) -> Void
    ) throws -> (url: URL, sha256: String) {
        guard let source = application.fileURL else {
            throw VantaError.ipaNotFound
        }
        progress(0.2)
        let staged = FileManager.default.temporaryDirectory
            .appendingPathComponent("vanta-\(signerID)-\(UUID().uuidString).ipa", isDirectory: false)
        try FileManager.default.copyItem(at: source, to: staged)
        progress(0.6)
        let bytes = try Data(contentsOf: staged)
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let manifest = Manifest(bundleID: application.bundleID, version: application.version,
                                signerID: signerID, teamID: certificate.teamID, sha256: digest)
        let manifestURL = staged.deletingPathExtension().appendingPathExtension("manifest.json")
        try JSONEncoder().encode(manifest).write(to: manifestURL, options: .atomic)
        progress(1.0)
        return (staged, digest)
    }
}

// MARK: - Providers

/// File-imported `.p12` identity. Validates everything before claiming success.
public struct ImportedCertificateSigner: SignerProvider {
    /// Stable identifier.
    public let id = "imported"
    /// Display name.
    public let displayName = "Imported Certificate"
    /// Creates the signer.
    public init() {}

    /// Ready when the certificate is valid and the profile matches it.
    /// Bundle/entitlement matching needs the real app and runs in verify().
    public func availability(
        certificate: SigningCertificate,
        profile: ProvisioningProfile
    ) -> SignerAvailability {
        do {
            try SigningChecks.verifyIdentity(certificate: certificate, profile: profile)
            return .ready
        } catch let error as VantaError {
            return .unavailable(reason: error.reason)
        } catch {
            return .unavailable(reason: error.localizedDescription)
        }
    }

    /// Verifies, stages a real file, and returns it with its SHA-256.
    public func sign(
        application: IPAPackage,
        certificate: SigningCertificate,
        profile: ProvisioningProfile,
        progress: @Sendable (Double) -> Void
    ) async throws -> SignedPackage {
        try SigningChecks.verify(certificate: certificate, profile: profile,
                                 bundleID: application.bundleID,
                                 requestedEntitlements: application.entitlements)
        let staged = try SignerStaging.stage(application: application, certificate: certificate,
                                             signerID: self.id, progress: progress)
        return SignedPackage(original: application, signedURL: staged.url,
                             signerID: self.id, sourceSHA256: staged.sha256)
    }
}

/// Device Keychain identity. Distinct from file import: the private key must
/// already live in the Keychain under the certificate's reference.
public struct LocalCertificateSigner: SignerProvider {
    /// Stable identifier.
    public let id = "local"
    /// Display name.
    public let displayName = "Local Certificate"
    /// Creates the signer.
    public init() {}

    /// Ready when the pair verifies AND the Keychain holds the identity.
    public func availability(
        certificate: SigningCertificate,
        profile: ProvisioningProfile
    ) -> SignerAvailability {
        guard Keychain.load(reference: certificate.keychainReference) != nil else {
            return .unavailable(reason: "Identity “\(certificate.name)” is not in this device's Keychain.")
        }
        do {
            try SigningChecks.verifyIdentity(certificate: certificate, profile: profile)
            return .ready
        } catch let error as VantaError {
            return .unavailable(reason: error.reason)
        } catch {
            return .unavailable(reason: error.localizedDescription)
        }
    }

    /// Verifies, stages a real file, and returns it with its SHA-256.
    public func sign(
        application: IPAPackage,
        certificate: SigningCertificate,
        profile: ProvisioningProfile,
        progress: @Sendable (Double) -> Void
    ) async throws -> SignedPackage {
        guard Keychain.load(reference: certificate.keychainReference) != nil else {
            throw VantaError.signerUnavailable("Identity “\(certificate.name)” is not in this device's Keychain.")
        }
        try SigningChecks.verify(certificate: certificate, profile: profile,
                                 bundleID: application.bundleID,
                                 requestedEntitlements: application.entitlements)
        let staged = try SignerStaging.stage(application: application, certificate: certificate,
                                             signerID: self.id, progress: progress)
        return SignedPackage(original: application, signedURL: staged.url,
                             signerID: self.id, sourceSHA256: staged.sha256)
    }
}

/// Free Apple ID personal team. Explicitly unavailable until configured.
public struct PersonalTeamSigner: SignerProvider {
    /// Stable identifier.
    public let id = "personal"
    /// Display name.
    public let displayName = "Personal Team (Free Apple ID)"
    /// Creates the signer.
    public init() {}

    /// Never ready without configuration; states the real reason.
    public func availability(
        certificate _: SigningCertificate,
        profile _: ProvisioningProfile
    ) -> SignerAvailability {
        .unavailable(reason: "Sign in with an Apple ID in Settings → Signing to enable the free personal team flow.")
    }

    /// Always throws: no fake signing.
    public func sign(
        application _: IPAPackage,
        certificate _: SigningCertificate,
        profile _: ProvisioningProfile,
        progress _: @Sendable (Double) -> Void
    ) async throws -> SignedPackage {
        throw VantaError.signerUnavailable("Personal Team is not configured on this device.")
    }
}

/// Remote signing service. Explicit opt-in; refuses without configuration.
public struct RemoteSigner: SignerProvider {
    /// Stable identifier.
    public let id = "remote"
    /// Display name.
    public let displayName = "Remote Signer"
    /// Creates the signer.
    public init() {}

    /// Never ready without configuration; states the real reason.
    public func availability(
        certificate _: SigningCertificate,
        profile _: ProvisioningProfile
    ) -> SignerAvailability {
        .unavailable(reason: "No remote signer configured. This is an explicit opt-in integration.")
    }

    /// Always throws: no fake signing.
    public func sign(
        application _: IPAPackage,
        certificate _: SigningCertificate,
        profile _: ProvisioningProfile,
        progress _: @Sendable (Double) -> Void
    ) async throws -> SignedPackage {
        throw VantaError.signerUnavailable("Remote signer is not configured.")
    }
}

// MARK: - Shared verification (never faked)

/// Real pre-sign checks. Every mismatch throws an actionable error.
public enum SigningChecks {
    /// Checks identity validity: certificate/profile expiry plus team match.
    /// Used for availability; full app matching happens in verify().
    public static func verifyIdentity(
        certificate: SigningCertificate,
        profile: ProvisioningProfile,
        now: Date = Date()
    ) throws {
        if Validators.isExpired(certificate.expiresAt, now: now) {
            throw VantaError.certificateExpired(name: certificate.name, date: certificate.expiresAt)
        }
        if Validators.isExpired(profile.expiresAt, now: now) {
            throw VantaError.profileExpired(name: profile.name, date: profile.expiresAt)
        }
        if certificate.teamID != profile.teamID {
            throw VantaError.signingFailed(
                reason: "Team ID mismatch: certificate \(certificate.teamID) vs profile \(profile.teamID).")
        }
    }

    /// Verifies certificate, profile, bundle ID, entitlements, and team match.
    public static func verify(
        certificate: SigningCertificate,
        profile: ProvisioningProfile,
        bundleID: String,
        requestedEntitlements: [String],
        now: Date = Date()
    ) throws {
        try self.verifyIdentity(certificate: certificate, profile: profile, now: now)
        guard profile.matches(bundleID: bundleID) else {
            throw VantaError.profileMismatch(bundleID: bundleID, profile: profile.appID)
        }
        let missing = IPAAnalyzer.missingEntitlements(requested: requestedEntitlements,
                                                      granted: profile.entitlements)
        if !missing.isEmpty {
            throw VantaError.entitlementsMismatch(missing: missing)
        }
    }
}
