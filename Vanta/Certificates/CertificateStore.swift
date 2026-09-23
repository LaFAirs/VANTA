import Foundation

/// In-memory registry + Keychain refs for certificates and profiles.
public actor CertificateStore {
    /// Shared instance.
    public static let shared = CertificateStore()
    private var certificates: [SigningCertificate] = []
    private var profiles: [ProvisioningProfile] = []

    /// All known certificates.
    public func certificatesList() -> [SigningCertificate] { self.certificates }

    /// All known profiles.
    public func profilesList() -> [ProvisioningProfile] { self.profiles }

    /// Registers a certificate.
    public func addCertificate(_ cert: SigningCertificate) { self.certificates.append(cert) }

    /// Registers a profile.
    public func addProfile(_ profile: ProvisioningProfile) { self.profiles.append(profile) }

    /// Removes a certificate and wipes its Keychain reference.
    public func removeCertificate(id: UUID) {
        if let cert = certificates.first(where: { $0.id == id }) {
            Keychain.delete(reference: cert.keychainReference)
        }
        certificates.removeAll { $0.id == id }
    }

    /// Removes a profile.
    public func removeProfile(id: UUID) { profiles.removeAll { $0.id == id } }

    /// Profiles eligible for a bundle ID (match + not expired).
    public func eligibleProfiles(bundleID: String, now: Date = Date()) -> [ProvisioningProfile] {
        self.profiles.filter { $0.matches(bundleID: bundleID) && !Validators.isExpired($0.expiresAt, now: now) }
    }

    /// Certificates that have not expired.
    public func activeCertificates(now: Date = Date()) -> [SigningCertificate] {
        self.certificates.filter { !Validators.isExpired($0.expiresAt, now: now) }
    }
}
