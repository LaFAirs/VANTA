import Foundation

// MARK: - Clock

/// Injectable clock so time logic is testable without touching the system clock.
public protocol DateProvider: Sendable {
    /// The current time.
    var now: Date { get }
}

/// Production clock backed by the system time.
public struct SystemClock: DateProvider, Sendable {
    /// Creates the system clock.
    public init() {}
    /// The current system time.
    public var now: Date { Date() }
}

/// Frozen clock for deterministic tests.
public struct FixedClock: DateProvider, Sendable {
    /// The frozen time.
    public let now: Date
    /// Creates a clock frozen at the given date.
    public init(now: Date) { self.now = now }
}

// MARK: - App lifecycle

/// Lifecycle state of a managed app.
public enum AppStatus: String, Codable, Sendable {
    /// Installed and valid.
    case installed
    /// Expiry approaching, refresh recommended.
    case needsRefresh
    /// Expired, refresh required.
    case expired
    /// Currently being signed.
    case signing
    /// Currently being verified.
    case verifying
    /// Currently being installed.
    case installing
    /// Last operation failed.
    case failed

    /// Human-readable label.
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

/// An app managed by VANTA.
public struct ManagedApp: Identifiable, Codable, Sendable {
    /// Stable identity.
    public let id: UUID
    /// Display name.
    public let name: String
    /// Bundle identifier.
    public let bundleID: String
    /// Marketing version.
    public let version: String
    /// Build number.
    public let build: String
    /// Current lifecycle state.
    public private(set) var status: AppStatus
    /// Signature expiry, if known.
    public private(set) var expiresAt: Date?
    /// Signing team, if known.
    public let teamID: String?
    /// Repository this app came from, if any.
    public let sourceRepository: String?
    /// Remote icon URL, if any.
    public let iconURL: URL?
    /// Last successful refresh, if any.
    public private(set) var lastRefreshed: Date?

    /// Creates a managed app, validating metadata. Throws on invalid input.
    public init(
        id: UUID = UUID(),
        name: String,
        bundleID: String,
        version: String,
        build: String = "1",
        status: AppStatus = .installed,
        expiresAt: Date? = nil,
        teamID: String? = nil,
        sourceRepository: String? = nil,
        iconURL: URL? = nil,
        lastRefreshed: Date? = nil
    ) throws {
        guard !name.isEmpty else {
            throw VantaError.ipaCorrupt(reason: "Invalid app metadata: name is empty.")
        }
        guard Validators.isValidBundleID(bundleID) else {
            throw VantaError.ipaCorrupt(reason: "Invalid app metadata: bad bundle ID “\(bundleID)”.")
        }
        guard Validators.isValidVersion(version) else {
            throw VantaError.ipaCorrupt(reason: "Invalid app metadata: bad version “\(version)”.")
        }
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.version = version
        self.build = build
        self.status = status
        self.expiresAt = expiresAt
        self.teamID = teamID
        self.sourceRepository = sourceRepository
        self.iconURL = iconURL
        self.lastRefreshed = lastRefreshed
    }

    /// Marks the app refreshed with a new expiry.
    public mutating func markRefreshed(expiresAt: Date?, clock: any DateProvider = SystemClock()) {
        self.status = .installed
        self.expiresAt = expiresAt
        self.lastRefreshed = clock.now
    }

    /// Updates the lifecycle state.
    public mutating func updateStatus(_ status: AppStatus) {
        self.status = status
    }
}

// MARK: - IPA analysis result

/// Metadata extracted from an IPA.
public struct IPAPackage: Identifiable, Codable, Sendable {
    /// Stable identity.
    public let id: UUID
    /// Display name.
    public let name: String
    /// Bundle identifier.
    public let bundleID: String
    /// Marketing version.
    public let version: String
    /// Build number.
    public let build: String
    /// Minimum OS version.
    public let minimumOS: String
    /// Executable architectures.
    public let architectures: [String]
    /// Requested entitlements.
    public let entitlements: [String]
    /// Embedded frameworks.
    public let frameworks: [String]
    /// Embedded plugins/extensions.
    public let plugins: [String]
    /// Signing team, if present.
    public let teamID: String?
    /// Local file location, if imported.
    public let fileURL: URL?
    /// File size in bytes.
    public let fileSize: Int64

    /// Creates a package, validating metadata. Throws on invalid input.
    public init(
        id: UUID = UUID(),
        name: String,
        bundleID: String,
        version: String,
        build: String = "1",
        minimumOS: String = "17.0",
        architectures: [String] = ["arm64"],
        entitlements: [String] = [],
        frameworks: [String] = [],
        plugins: [String] = [],
        teamID: String? = nil,
        fileURL: URL? = nil,
        fileSize: Int64 = 0
    ) throws {
        guard !name.isEmpty else {
            throw VantaError.ipaCorrupt(reason: "Invalid package metadata: name is empty.")
        }
        guard Validators.isValidBundleID(bundleID) else {
            throw VantaError.ipaCorrupt(reason: "Invalid package metadata: bad bundle ID “\(bundleID)”.")
        }
        guard Validators.isValidVersion(version) else {
            throw VantaError.ipaCorrupt(reason: "Invalid package metadata: bad version “\(version)”.")
        }
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.version = version
        self.build = build
        self.minimumOS = minimumOS
        self.architectures = architectures
        self.entitlements = entitlements
        self.frameworks = frameworks
        self.plugins = plugins
        self.teamID = teamID
        self.fileURL = fileURL
        self.fileSize = fileSize
    }
}

// MARK: - Certificates & profiles

/// Validity state of a certificate.
public enum CertificateStatus: String, Codable, Sendable {
    /// Valid.
    case active
    /// Expires within 14 days.
    case expiringSoon
    /// Past expiry.
    case expired
    /// Failed validation.
    case invalid
}

/// An Apple signing identity (metadata only; keys stay in the Keychain).
public struct SigningCertificate: Identifiable, Codable, Sendable {
    /// Stable identity.
    public let id: UUID
    /// Common name.
    public let name: String
    /// Apple Team ID.
    public let teamID: String
    /// Expiry date.
    public let expiresAt: Date
    /// Validity state at creation.
    public let status: CertificateStatus
    /// Opaque Keychain reference; never the key itself.
    public let keychainReference: String

    /// Creates a certificate record.
    public init(
        id: UUID = UUID(),
        name: String,
        teamID: String,
        expiresAt: Date,
        status: CertificateStatus = .active,
        keychainReference: String = ""
    ) {
        self.id = id
        self.name = name
        self.teamID = teamID
        self.expiresAt = expiresAt
        self.status = status
        self.keychainReference = keychainReference
    }

    /// Whole days until expiry (negative when expired).
    public func daysRemaining(using clock: any DateProvider = SystemClock()) -> Int {
        Calendar.current.dateComponents([.day], from: clock.now, to: self.expiresAt).day ?? 0
    }
}

/// A provisioning profile (metadata parsed from `.mobileprovision`).
public struct ProvisioningProfile: Identifiable, Codable, Sendable {
    /// Stable identity.
    public let id: UUID
    /// Profile name.
    public let name: String
    /// Application identifier (e.g. TEAMID.com.example.app or wildcard).
    public let appID: String
    /// Apple Team ID.
    public let teamID: String
    /// Expiry date.
    public let expiresAt: Date
    /// Granted entitlement keys.
    public let entitlements: [String]

    /// Creates a profile record.
    public init(
        id: UUID = UUID(),
        name: String,
        appID: String,
        teamID: String,
        expiresAt: Date,
        entitlements: [String] = []
    ) {
        self.id = id
        self.name = name
        self.appID = appID
        self.teamID = teamID
        self.expiresAt = expiresAt
        self.entitlements = entitlements
    }

    /// True when this profile may sign the given bundle ID (exact or wildcard).
    public func matches(bundleID: String) -> Bool {
        let pattern = self.matchPattern
        if pattern == "*" || pattern.hasSuffix(".*") {
            let prefix = pattern
                .replacingOccurrences(of: ".*", with: "")
                .replacingOccurrences(of: "*", with: "")
            return bundleID == prefix || bundleID.hasPrefix(prefix + ".") || prefix.isEmpty
        }
        return pattern == bundleID
    }

    /// A concrete bundle ID this profile covers, if the profile is non-wildcard.
    /// Wildcard profiles return nil: they match many IDs, which is checked
    /// at sign time with the real app instead of guessed here.
    public var coveredBundleID: String? {
        let pattern = self.matchPattern
        guard !pattern.contains("*"), !pattern.isEmpty else { return nil }
        return pattern
    }

    /// The app-ID pattern without its team prefix.
    private var matchPattern: String {
        self.appID.contains(".")
            ? String(self.appID.split(separator: ".", maxSplits: 1).last ?? "")
            : self.appID
    }
}

// MARK: - Repositories

/// A single app offered by a repository.
public struct RepoApp: Identifiable, Codable, Sendable, Hashable {
    /// Stable identity (independent of version so updates replace cleanly).
    public let id: UUID
    /// Display name.
    public let name: String
    /// Bundle identifier.
    public let bundleIdentifier: String
    /// Marketing version.
    public let version: String
    /// Release date, if provided.
    public let versionDate: Date?
    /// IPA download URL.
    public let downloadURL: URL
    /// Icon URL, if provided.
    public let iconURL: URL?
    /// Developer name.
    public let developer: String
    /// Description.
    public let localizedDescription: String
    /// Changelog, if provided.
    public let changelog: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case bundleIdentifier
        case version
        case versionDate
        case downloadURL
        case iconURL
        case developer
        case localizedDescription
        case changelog
    }

    /// Creates a repository app entry.
    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        version: String,
        versionDate: Date? = nil,
        downloadURL: URL,
        iconURL: URL? = nil,
        developer: String = "",
        localizedDescription: String = "",
        changelog: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.versionDate = versionDate
        self.downloadURL = downloadURL
        self.iconURL = iconURL
        self.developer = developer
        self.localizedDescription = localizedDescription
        self.changelog = changelog
    }

    /// Decodes an entry, assigning a fresh local identity.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        self.version = try container.decode(String.self, forKey: .version)
        self.versionDate = try container.decodeIfPresent(Date.self, forKey: .versionDate)
        self.downloadURL = try container.decode(URL.self, forKey: .downloadURL)
        self.iconURL = try container.decodeIfPresent(URL.self, forKey: .iconURL)
        self.developer = try container.decode(String.self, forKey: .developer)
        self.localizedDescription = try container.decode(String.self, forKey: .localizedDescription)
        self.changelog = try container.decodeIfPresent(String.self, forKey: .changelog)
    }

    /// Business-key equality: same app, regardless of local identity.
    public static func == (lhs: RepoApp, rhs: RepoApp) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.version == rhs.version
    }

    /// Hashes the business key.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.bundleIdentifier)
        hasher.combine(self.version)
    }
}

/// A user-added app repository.
public struct AppRepository: Identifiable, Codable, Sendable {
    /// Stable identity.
    public let id: UUID
    /// Display name.
    public let name: String
    /// Manifest URL.
    public let url: URL
    /// Reverse-DNS identifier.
    public let identifier: String
    /// Offered apps.
    public let apps: [RepoApp]
    /// Last successful fetch, if any.
    public let lastUpdated: Date?

    /// Creates a repository record.
    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        identifier: String,
        apps: [RepoApp] = [],
        lastUpdated: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.identifier = identifier
        self.apps = apps
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Misc

/// A dashboard activity event.
public struct ActivityEvent: Identifiable, Codable, Sendable {
    /// Stable identity.
    public let id: UUID
    /// When it happened.
    public let date: Date
    /// Message.
    public let message: String
    /// Kind (info/success/warning/error).
    public let kind: String

    /// Creates an activity event.
    public init(id: UUID = UUID(), date: Date = Date(), message: String, kind: String = "info") {
        self.id = id
        self.date = date
        self.message = message
        self.kind = kind
    }
}

/// The output of a signer: a staged package plus its provenance.
public struct SignedPackage: Sendable {
    /// The analyzed input.
    public let original: IPAPackage
    /// Staged output file (real file on disk, never a placeholder path).
    public let signedURL: URL
    /// Signer that produced it.
    public let signerID: String
    /// SHA-256 of the staged file.
    public let sourceSHA256: String

    /// Creates a signed package record.
    public init(original: IPAPackage, signedURL: URL, signerID: String, sourceSHA256: String) {
        self.original = original
        self.signedURL = signedURL
        self.signerID = signerID
        self.sourceSHA256 = sourceSHA256
    }
}
