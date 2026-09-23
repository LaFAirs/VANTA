import Foundation

/// In-memory registry + Keychain refs for certificates and profiles.
public actor CertificateStore {
    public static let shared = CertificateStore()
    private var certificates: [SigningCertificate] = []
    private var profiles: [ProvisioningProfile] = []

    public func certificatesList() -> [SigningCertificate] { certificates }
    public func profilesList() -> [ProvisioningProfile] { profiles }

    public func addCertificate(_ c: SigningCertificate) { certificates.append(c) }
    public func addProfile(_ p: ProvisioningProfile) { profiles.append(p) }

    public func removeCertificate(id: UUID) {
        if let c = certificates.first(where: { $0.id == id }) {
            Keychain.delete(reference: c.keychainReference)
        }
        certificates.removeAll { $0.id == id }
    }

    public func removeProfile(id: UUID) { profiles.removeAll { $0.id == id } }

    /// Profiles eligible for a bundle ID (match + not expired).
    public func eligibleProfiles(bundleID: String, now: Date = Date()) -> [ProvisioningProfile] {
        profiles.filter { $0.matches(bundleID: bundleID) && !Validators.isExpired($0.expiresAt, now: now) }
    }

    public func activeCertificates(now: Date = Date()) -> [SigningCertificate] {
        certificates.filter { !Validators.isExpired($0.expiresAt, now: now) }
    }
}
