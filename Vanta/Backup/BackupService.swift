import Foundation
import CryptoKit

/// Backup/restore of lists + settings. Secrets are AES-GCM encrypted;
/// private keys are never exported in plaintext — export refuses by design.
public actor BackupService {
    public struct Backup: Codable, Sendable {
        public var version: Int
        public var date: Date
        public var apps: [ManagedApp]
        public var repositories: [AppRepository]
        public var settings: [String: String]
        public init(apps: [ManagedApp], repositories: [AppRepository], settings: [String: String] = [:]) {
            self.version = 1; self.date = Date()
            self.apps = apps; self.repositories = repositories; self.settings = settings
        }
    }

    public static let shared = BackupService()

    public func makeBackup() async -> Backup {
        let apps = await ManagedAppStore.shared.all()
        let repos = await RepositoryStore.shared.all()
        return Backup(apps: apps, repositories: repos)
    }

    public func encode(_ b: Backup) throws -> Data {
        try JSONEncoder().encode(b)
    }

    public func decode(_ data: Data) throws -> Backup {
        do { return try JSONDecoder().decode(Backup.self, from: data) }
        catch { throw VantaError.backupFailed(reason: "Backup file is invalid: \(error.localizedDescription)") }
    }

    /// Encrypt with a user-supplied passphrase (SHA256 → symmetric key, AES-GCM).
    public func encrypt(_ data: Data, passphrase: String) throws -> Data {
        let key = SymmetricKey(data: SHA256.hash(data: Data(passphrase.utf8)))
        guard let combined = try AES.GCM.seal(data, using: key).combined else {
            throw VantaError.backupFailed(reason: "Encryption produced no output.")
        }
        return combined
    }

    public func decrypt(_ data: Data, passphrase: String) throws -> Data {
        let key = SymmetricKey(data: SHA256.hash(data: Data(passphrase.utf8)))
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
    }

    /// Rotates the encryption passphrase: decrypts with the old one and
    /// re-encrypts with the new one. Throws when the old passphrase is wrong.
    public func rotate(_ data: Data, oldPassphrase: String, newPassphrase: String) throws -> Data {
        let plain = try self.decrypt(data, passphrase: oldPassphrase)
        return try self.encrypt(plain, passphrase: newPassphrase)
    }

    /// Wipes the given Keychain identity references (e.g. on full reset).
    /// Deletes references only; backup payloads must be deleted separately.
    public func wipeKeychainReferences(_ references: [String]) {
        for reference in references {
            Keychain.delete(reference: reference)
        }
    }

    public func refusePrivateKeyExport() -> VantaError {
        .backupFailed(reason: "Private keys are never exported. Identities stay in the Keychain; backups carry metadata only.")
    }

    /// Test-only seam: build a backup from explicit inputs without touching stores.
    public func makeBackupForTest(apps: [ManagedApp], repos: [AppRepository]) -> Backup {
        Backup(apps: apps, repositories: repos)
    }
}
