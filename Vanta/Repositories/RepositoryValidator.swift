import Foundation

/// Validates repository manifests before anything is downloaded.
public enum RepositoryValidator {
    public struct Manifest: Codable {
        public var name: String
        public var identifier: String
        public var apps: [ManifestApp]
    }
    public struct ManifestApp: Codable {
        public var name: String
        public var bundleIdentifier: String
        public var version: String
        public var versionDate: Date?
        public var downloadURL: String
        public var iconURL: String?
        public var developer: String?
        public var localizedDescription: String?
        public var changelog: String?
    }

    public static func validate(data: Data, sourceURL: URL,
                                allowInsecure: Bool = false) throws -> AppRepository {
        try Validators.requireSecure(sourceURL, acknowledgedInsecure: allowInsecure)
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let manifest: Manifest
        do { manifest = try dec.decode(Manifest.self, from: data) }
        catch { throw VantaError.repositoryInvalid(reason: "Manifest is not valid JSON: \(error.localizedDescription)") }
        guard !manifest.name.isEmpty, !manifest.identifier.isEmpty else {
            throw VantaError.repositoryInvalid(reason: "Manifest is missing name/identifier.")
        }
        var apps: [RepoApp] = []
        for a in manifest.apps {
            guard Validators.isValidBundleID(a.bundleIdentifier) else {
                throw VantaError.repositoryInvalid(reason: "Invalid bundle ID “\(a.bundleIdentifier)” in \(manifest.name).")
            }
            guard Validators.isValidVersion(a.version) else {
                throw VantaError.repositoryInvalid(reason: "Invalid version “\(a.version)” for \(a.name).")
            }
            let dl = try Validators.parseURL(a.downloadURL)
            try Validators.requireSecure(dl, acknowledgedInsecure: allowInsecure)
            let icon = try a.iconURL.map { try Validators.parseURL($0) }
            apps.append(RepoApp(name: a.name, bundleIdentifier: a.bundleIdentifier,
                                version: a.version, versionDate: a.versionDate,
                                downloadURL: dl, iconURL: icon,
                                developer: a.developer ?? "",
                                localizedDescription: a.localizedDescription ?? "",
                                changelog: a.changelog))
        }
        return AppRepository(name: manifest.name, url: sourceURL,
                             identifier: manifest.identifier, apps: apps, lastUpdated: Date())
    }
}
