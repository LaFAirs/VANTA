import Foundation

/// Typed, user-facing errors. Every case maps to title + reason + remedy.
/// Never surface bare codes like "Error 13".
public enum VantaError: Error, LocalizedError, Equatable {
    case invalidURL(String)
    case insecureURL(URL)
    case ipaNotFound
    case ipaCorrupt(reason: String)
    case infoPlistMissing
    case unsupportedArchitecture(String)
    case certificateExpired(name: String, date: Date)
    case certificateInvalid(reason: String)
    case profileExpired(name: String, date: Date)
    case profileMismatch(bundleID: String, profile: String)
    case entitlementsMismatch(missing: [String])
    case signerUnavailable(String)
    case signingFailed(reason: String)
    case verificationFailed(reason: String)
    case installationUnavailable(reason: String)
    case refreshUnavailable(reason: String)
    case repositoryInvalid(reason: String)
    case backupFailed(reason: String)
    case keychainFailure(reason: String)
    case notAvailable(String)

    public var errorDescription: String? { title + "\n" + reason }

    public var title: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .insecureURL: return "Insecure connection"
        case .ipaNotFound: return "IPA not found"
        case .ipaCorrupt: return "IPA is corrupt"
        case .infoPlistMissing: return "Info.plist missing"
        case .unsupportedArchitecture: return "Unsupported architecture"
        case .certificateExpired: return "Certificate expired"
        case .certificateInvalid: return "Certificate invalid"
        case .profileExpired: return "Provisioning profile expired"
        case .profileMismatch: return "Signing failed"
        case .entitlementsMismatch: return "Entitlements mismatch"
        case .signerUnavailable: return "Signer unavailable"
        case .signingFailed: return "Signing failed"
        case .verificationFailed: return "Verification failed"
        case .installationUnavailable: return "Installation unavailable"
        case .refreshUnavailable: return "Refresh unavailable"
        case .repositoryInvalid: return "Repository invalid"
        case .backupFailed: return "Backup failed"
        case .keychainFailure: return "Secure storage failed"
        case .notAvailable: return "Not available"
        }
    }

    public var reason: String {
        switch self {
        case .invalidURL(let s): return "“\(s)” is not a valid URL."
        case .insecureURL(let u): return "\(u.host ?? u.absoluteString) uses plain HTTP. Use HTTPS or confirm explicitly."
        case .ipaNotFound: return "The IPA file could not be located."
        case .ipaCorrupt(let r): return r
        case .infoPlistMissing: return "No Info.plist was found inside Payload/*.app."
        case .unsupportedArchitecture(let a): return "Architecture “\(a)” is not supported on this device."
        case .certificateExpired(let n, let d): return "“\(n)” expired on \(d.formatted(date: .abbreviated, time: .omitted)). Import a current identity."
        case .certificateInvalid(let r): return r
        case .profileExpired(let n, let d): return "“\(n)” expired on \(d.formatted(date: .abbreviated, time: .omitted))."
        case .profileMismatch(let b, let p): return "The selected provisioning profile does not match this Bundle Identifier.\nBundle ID: \(b)\nProvisioning Profile: \(p)"
        case .entitlementsMismatch(let m): return "Missing entitlements: \(m.joined(separator: ", ")). Choose a profile that grants them."
        case .signerUnavailable(let s): return s
        case .signingFailed(let r): return r
        case .verificationFailed(let r): return r
        case .installationUnavailable(let r): return r
        case .refreshUnavailable(let r): return r
        case .repositoryInvalid(let r): return r
        case .backupFailed(let r): return r
        case .keychainFailure(let r): return r
        case .notAvailable(let r): return r
        }
    }

    /// Suggested user action label.
    public var remedy: String {
        switch self {
        case .profileMismatch: return "Choose another profile"
        case .insecureURL: return "Use HTTPS"
        case .certificateExpired, .profileExpired: return "Replace certificate"
        case .signerUnavailable, .installationUnavailable, .refreshUnavailable, .notAvailable: return "View requirements"
        default: return "Try again"
        }
    }
}
