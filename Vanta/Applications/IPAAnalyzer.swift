import Foundation

/// Pure IPA analyzer: parses Info.plist bytes + filename heuristics.
/// Real ZIP parsing happens on-device via the importer; this layer stays testable.
public enum IPAAnalyzer {
    /// Analyzed metadata.
    public struct Info: Sendable {
        /// Display name.
        public var name: String
        /// Bundle identifier.
        public var bundleID: String
        /// Marketing version.
        public var version: String
        /// Build number.
        public var build: String
        /// Minimum OS version.
        public var minimumOS: String
    }

    /// Parse an Info.plist dictionary (as extracted from Payload/*.app/Info.plist).
    public static func analyze(infoPlist: [String: Any]) throws -> Info {
        guard let bundleID = infoPlist["CFBundleIdentifier"] as? String, !bundleID.isEmpty else {
            throw VantaError.infoPlistMissing
        }
        guard Validators.isValidBundleID(bundleID) else {
            throw VantaError.ipaCorrupt(reason: "Invalid bundle identifier: \(bundleID)")
        }
        let name = (infoPlist["CFBundleDisplayName"] as? String)
            ?? (infoPlist["CFBundleName"] as? String) ?? bundleID
        let version = (infoPlist["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (infoPlist["CFBundleVersion"] as? String) ?? "1"
        let minOS = (infoPlist["MinimumOSVersion"] as? String) ?? "17.0"
        return Info(name: name, bundleID: bundleID, version: version, build: build, minimumOS: minOS)
    }

    /// Supported executable architectures for sideloading on modern devices.
    public static func supportedArchitectures(_ archs: [String]) throws -> [String] {
        let supported = archs.filter { $0 == "arm64" || $0 == "arm64e" }
        guard !supported.isEmpty else {
            throw VantaError.unsupportedArchitecture(archs.joined(separator: ", "))
        }
        return supported
    }

    /// Entitlement subset check: requested must be ⊆ granted by the profile.
    public static func missingEntitlements(requested: [String], granted: [String]) -> [String] {
        let grantedSet = Set(granted)
        return requested.filter { !grantedSet.contains($0) }
    }
}
