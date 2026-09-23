import Foundation
import Security

/// Keychain-backed identity references. Private keys never touch UserDefaults/files.
public enum Keychain {
    static let service = "com.vanta.app.identities"

    /// Stores identity data under a reference (device-only accessibility).
    @discardableResult
    public static func store(reference: String, data: Data) -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: reference,
                                    kSecValueData as String: data,
                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Loads identity data for a reference, if present.
    public static func load(reference: String) -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: reference,
                                    kSecReturnData as String: true]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess else { return nil }
        return out as? Data
    }

    /// Deletes an identity reference.
    public static func delete(reference: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: reference]
        SecItemDelete(query as CFDictionary)
    }
}

/// Parses .p12 metadata claims supplied by the importer (real PKCS12 parsing
/// happens via SecPKCS12Import on-device; this struct keeps UI/test layers pure).
public enum CertificateParser {
    /// Identity claims extracted from an import.
    public struct Claim: Sendable {
        /// Common name.
        public var commonName: String
        /// Apple Team ID.
        public var teamID: String
        /// Expiry date.
        public var expiresAt: Date

        /// Creates a claim.
        public init(commonName: String, teamID: String, expiresAt: Date) {
            self.commonName = commonName
            self.teamID = teamID
            self.expiresAt = expiresAt
        }
    }

    /// Validity state for an expiry date.
    public static func status(for expiresAt: Date, now: Date = Date()) -> CertificateStatus {
        if Validators.isExpired(expiresAt, now: now) { return .expired }
        if Validators.daysUntil(expiresAt, now: now) <= 14 { return .expiringSoon }
        return .active
    }

    /// Validates a claim into a certificate record. Throws on invalid input.
    public static func validate(_ claim: Claim, now: Date = Date()) throws -> SigningCertificate {
        guard !claim.commonName.isEmpty, !claim.teamID.isEmpty else {
            throw VantaError.certificateInvalid(reason: "Certificate is missing its identity (CN/Team ID).")
        }
        if Validators.isExpired(claim.expiresAt, now: now) {
            throw VantaError.certificateExpired(name: claim.commonName, date: claim.expiresAt)
        }
        return SigningCertificate(name: claim.commonName, teamID: claim.teamID,
                                  expiresAt: claim.expiresAt,
                                  status: status(for: claim.expiresAt, now: now),
                                  keychainReference: UUID().uuidString)
    }
}

/// Parses .mobileprovision plists (CMS-wrapped on disk; unwrapping happens in
/// `ProvisioningProfileStore` with real data — this stays a pure plist mapper).
public enum ProvisioningProfileParser {
    /// Parses a profile plist dictionary. Throws on missing or expired data.
    public static func parse(plist: [String: Any]) throws -> ProvisioningProfile {
        guard let name = plist["Name"] as? String,
              let appID = (plist["Entitlements"] as? [String: Any])?["application-identifier"] as? String,
              let teamID = (plist["TeamIdentifier"] as? [String])?.first ?? (plist["TeamIdentifier"] as? String),
              let expiry = plist["ExpirationDate"] as? Date else {
            throw VantaError.repositoryInvalid(reason: "Provisioning profile plist is missing required fields.")
        }
        if Validators.isExpired(expiry) {
            throw VantaError.profileExpired(name: name, date: expiry)
        }
        let ents = (plist["Entitlements"] as? [String: Any])?.keys.sorted() ?? []
        return ProvisioningProfile(name: name, appID: appID, teamID: teamID,
                                   expiresAt: expiry, entitlements: ents)
    }
}
