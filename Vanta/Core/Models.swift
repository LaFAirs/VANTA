import Foundation

// MARK: - App lifecycle

public enum AppStatus: String, Codable, Sendable {
    case installed, needsRefresh, expired, signing, verifying, installing, failed
    public var label: String {
        switch self {
        case .installed: return "Installed"
        case .needsRefresh: return "Needs refresh"
        case .expired: return "Expired"
        case .signing: return "Signing"
        case .verifying: return "Verifying"
        case .installing: return "Installing"
        case .failed: return "Failed"
        }
    }
}

public struct ManagedApp: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var bundleID: String
    public var version: String
    public var build: String
    public var status: AppStatus
    public var expiresAt: Date?
    public var teamID: String?
    public var sourceRepository: String?
    public var iconURL: URL?
    public var lastRefreshed: Date?

    public init(id: UUID = UUID(), name: String, bundleID: String, version: String,
                build: String = "1", status: AppStatus = .installed,
                expiresAt: Date? = nil, teamID: String? = nil,
                sourceRepository: String? = nil, iconURL: URL? = nil,
                lastRefreshed: Date? = nil) {
        self.id = id; self.name = name; self.bundleID = bundleID; self.version = version
        self.build = build; self.status = status; self.expiresAt = expiresAt
        self.teamID = teamID; self.sourceRepository = sourceRepository
        self.iconURL = iconURL; self.lastRefreshed = lastRefreshed
    }
}

// MARK: - IPA analysis result

public struct IPAPackage: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var bundleID: String
    public var version: String
    public var build: String
    public var minimumOS: String
    public var architectures: [String]
    public var entitlements: [String]
    public var frameworks: [String]
    public var plugins: [String]
    public var teamID: String?
    public var fileURL: URL?
    public var fileSize: Int64

    public init(id: UUID = UUID(), name: String, bundleID: String, version: String,
                build: String = "1", minimumOS: String = "17.0",
                architectures: [String] = ["arm64"], entitlements: [String] = [],
                frameworks: [String] = [], plugins: [String] = [],
                teamID: String? = nil, fileURL: URL? = nil, fileSize: Int64 = 0) {
        self.id = id; self.name = name; self.bundleID = bundleID; self.version = version
        self.build = build; self.minimumOS = minimumOS; self.architectures = architectures
        self.entitlements = entitlements; self.frameworks = frameworks; self.plugins = plugins
        self.teamID = teamID; self.fileURL = fileURL; self.fileSize = fileSize
    }
}

// MARK: - Certificates & profiles

public enum CertificateStatus: String, Codable, Sendable {
    case active, expiringSoon, expired, invalid
}

public struct SigningCertificate: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var teamID: String
    public var expiresAt: Date
    public var status: CertificateStatus
    public var keychainReference: String  // opaque ref; never the key itself

    public init(id: UUID = UUID(), name: String, teamID: String, expiresAt: Date,
                status: CertificateStatus = .active, keychainReference: String = "") {
        self.id = id; self.name = name; self.teamID = teamID
        self.expiresAt = expiresAt; self.status = status
        self.keychainReference = keychainReference
    }

    public var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
    }
}

public struct ProvisioningProfile: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var appID: String       // e.g. TEAMID.com.example.app or wildcard
    public var teamID: String
    public var expiresAt: Date
    public var entitlements: [String]

    public init(id: UUID = UUID(), name: String, appID: String, teamID: String,
                expiresAt: Date, entitlements: [String] = []) {
        self.id = id; self.name = name; self.appID = appID
        self.teamID = teamID; self.expiresAt = expiresAt; self.entitlements = entitlements
    }

    /// True when this profile may sign the given bundle ID (exact or wildcard).
    public func matches(bundleID: String) -> Bool {
        let pattern = appID.contains(".") ? String(appID.split(separator: ".", maxSplits: 1).last ?? "") : appID
        if pattern == "*" || pattern.hasSuffix(".*") {
            let prefix = pattern.replacingOccurrences(of: ".*", with: "").replacingOccurrences(of: "*", with: "")
            return bundleID == prefix || bundleID.hasPrefix(prefix + ".") || prefix.isEmpty
        }
        return pattern == bundleID
    }
}

// MARK: - Repositories

public struct RepoApp: Identifiable, Codable, Sendable {
    public var id: String { bundleIdentifier + "@" + version }
    public var name: String
    public var bundleIdentifier: String
    public var version: String
    public var versionDate: Date?
    public var downloadURL: URL
    public var iconURL: URL?
    public var developer: String
    public var localizedDescription: String
    public var changelog: String?

    public init(name: String, bundleIdentifier: String, version: String,
                versionDate: Date? = nil, downloadURL: URL, iconURL: URL? = nil,
                developer: String = "", localizedDescription: String = "", changelog: String? = nil) {
        self.name = name; self.bundleIdentifier = bundleIdentifier; self.version = version
        self.versionDate = versionDate; self.downloadURL = downloadURL; self.iconURL = iconURL
        self.developer = developer; self.localizedDescription = localizedDescription; self.changelog = changelog
    }
}

public struct AppRepository: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var url: URL
    public var identifier: String
    public var apps: [RepoApp]
    public var lastUpdated: Date?

    public init(id: UUID = UUID(), name: String, url: URL, identifier: String,
                apps: [RepoApp] = [], lastUpdated: Date? = nil) {
        self.id = id; self.name = name; self.url = url
        self.identifier = identifier; self.apps = apps; self.lastUpdated = lastUpdated
    }
}

// MARK: - Misc

public struct ActivityEvent: Identifiable, Codable, Sendable {
    public var id: UUID
    public var date: Date
    public var message: String
    public var kind: String
    public init(id: UUID = UUID(), date: Date = Date(), message: String, kind: String = "info") {
        self.id = id; self.date = date; self.message = message; self.kind = kind
    }
}

public struct SignedPackage: Sendable {
    public var original: IPAPackage
    public var signedURL: URL
    public var signerID: String
    public init(original: IPAPackage, signedURL: URL, signerID: String) {
        self.original = original; self.signedURL = signedURL; self.signerID = signerID
    }
}
