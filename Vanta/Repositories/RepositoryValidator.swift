import Foundation

/// Validates repository manifests before anything is downloaded.
public enum RepositoryValidator {
    /// Decoded manifest envelope.
    public struct Manifest: Codable {
        /// Repository name.
        public var name: String
        /// Reverse-DNS identifier.
        public var identifier: String
        /// Offered apps.
        public var apps: [ManifestApp]
    }

    /// Decoded manifest app entry.
    public struct ManifestApp: Codable {
        /// Display name.
        public var name: String
        /// Bundle identifier.
        public var bundleIdentifier: String
        /// Marketing version.
        public var version: String
        /// Release date, if provided.
        public var versionDate: Date?
        /// IPA download URL string.
        public var downloadURL: String
        /// Icon URL string, if provided.
        public var iconURL: String?
        /// Developer name, if provided.
        public var developer: String?
        /// Description, if provided.
        public var localizedDescription: String?
        /// Changelog, if provided.
        public var changelog: String?
    }

    /// Validates manifest data into a repository record.
    public static func validate(data: Data, sourceURL: URL,
                                allowInsecure: Bool = false) throws -> AppRepository {
        try Validators.requireSecure(sourceURL, acknowledgedInsecure: allowInsecure)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest: Manifest
        do {
            manifest = try decoder.decode(Manifest.self, from: data)
        } catch {
            throw VantaError.repositoryInvalid(reason: "Manifest is not valid JSON: \(error.localizedDescription)")
        }
        guard !manifest.name.isEmpty, !manifest.identifier.isEmpty else {
            throw VantaError.repositoryInvalid(reason: "Manifest is missing name/identifier.")
        }
        var apps: [RepoApp] = []
        for manifestApp in manifest.apps {
            guard Validators.isValidBundleID(manifestApp.bundleIdentifier) else {
                throw VantaError.repositoryInvalid(
                    reason: "Invalid bundle ID “\(manifestApp.bundleIdentifier)” in \(manifest.name).")
            }
            guard Validators.isValidVersion(manifestApp.version) else {
                throw VantaError.repositoryInvalid(
                    reason: "Invalid version “\(manifestApp.version)” for \(manifestApp.name).")
            }
            let download = try Validators.parseURL(manifestApp.downloadURL)
            try Validators.requireSecure(download, acknowledgedInsecure: allowInsecure)
            let icon = try manifestApp.iconURL.map { try Validators.parseURL($0) }
            apps.append(RepoApp(name: manifestApp.name, bundleIdentifier: manifestApp.bundleIdentifier,
                                version: manifestApp.version, versionDate: manifestApp.versionDate,
                                downloadURL: download, iconURL: icon,
                                developer: manifestApp.developer ?? "",
                                localizedDescription: manifestApp.localizedDescription ?? "",
                                changelog: manifestApp.changelog))
        }
        return AppRepository(name: manifest.name, url: sourceURL,
                             identifier: manifest.identifier, apps: apps, lastUpdated: Date())
    }
}
