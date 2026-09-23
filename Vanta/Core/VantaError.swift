import Foundation

/// Typed, user-facing errors. Every case maps to a title, reason, remedy,
/// and a stable log code (`VANTA_Exxx`) for correlating logs with failures.
/// Never surface bare codes like "Error 13".
public enum VantaError: Error, LocalizedError, Equatable {
    /// Malformed URL string.
    case invalidURL(String)
    /// Plain-HTTP URL without explicit acknowledgement.
    case insecureURL(URL)
    /// IPA file missing.
    case ipaNotFound
    /// IPA unreadable.
    case ipaCorrupt(reason: String)
    /// No Info.plist inside the app bundle.
    case infoPlistMissing
    /// No supported executable slice.
    case unsupportedArchitecture(String)
    /// Expired signing identity.
    case certificateExpired(name: String, date: Date)
    /// Unparseable signing identity.
    case certificateInvalid(reason: String)
    /// Expired provisioning profile.
    case profileExpired(name: String, date: Date)
    /// Profile does not cover the bundle ID.
    case profileMismatch(bundleID: String, profile: String)
    /// Requested entitlements not granted.
    case entitlementsMismatch(missing: [String])
    /// Signer not configured.
    case signerUnavailable(String)
    /// Signing step failed.
    case signingFailed(reason: String)
    /// Post-sign verification failed.
    case verificationFailed(reason: String)
    /// On-device install unavailable here.
    case installationUnavailable(reason: String)
    /// Refresh unavailable here.
    case refreshUnavailable(reason: String)
    /// Repository manifest invalid.
    case repositoryInvalid(reason: String)
    /// Backup/restore failed.
    case backupFailed(reason: String)
    /// Keychain access failed.
    case keychainFailure(reason: String)
    /// Feature unavailable in this environment.
    case notAvailable(String)

    /// Stable code for log correlation (`VANTA_E400`…).
    public var code: String {
        switch self {
        case .invalidURL: return "VANTA_E400"
        case .insecureURL: return "VANTA_E401"
        case .ipaNotFound: return "VANTA_E402"
        case .ipaCorrupt: return "VANTA_E403"
        case .infoPlistMissing: return "VANTA_E404"
        case .unsupportedArchitecture: return "VANTA_E405"
        case .certificateExpired: return "VANTA_E410"
        case .certificateInvalid: return "VANTA_E411"
        case .profileExpired: return "VANTA_E412"
        case .profileMismatch: return "VANTA_E413"
        case .entitlementsMismatch: return "VANTA_E414"
        case .signerUnavailable: return "VANTA_E420"
        case .signingFailed: return "VANTA_E421"
        case .verificationFailed: return "VANTA_E422"
        case .installationUnavailable: return "VANTA_E423"
        case .refreshUnavailable: return "VANTA_E424"
        case .repositoryInvalid: return "VANTA_E430"
        case .backupFailed: return "VANTA_E431"
        case .keychainFailure: return "VANTA_E432"
        case .notAvailable: return "VANTA_E499"
        }
    }

    /// Short title (localized; English default matches legacy strings).
    public var title: String {
        switch self {
        case .invalidURL:
            return String(localized: "vanta.error.title.invalidURL", defaultValue: "Invalid URL")
        case .insecureURL:
            return String(localized: "vanta.error.title.insecureURL", defaultValue: "Insecure connection")
        case .ipaNotFound:
            return String(localized: "vanta.error.title.ipaNotFound", defaultValue: "IPA not found")
        case .ipaCorrupt:
            return String(localized: "vanta.error.title.ipaCorrupt", defaultValue: "IPA is corrupt")
        case .infoPlistMissing:
            return String(localized: "vanta.error.title.infoPlistMissing", defaultValue: "Info.plist missing")
        case .unsupportedArchitecture:
            return String(
                localized: "vanta.error.title.unsupportedArchitecture",
                defaultValue: "Unsupported architecture"
            )
        case .certificateExpired:
            return String(localized: "vanta.error.title.certificateExpired", defaultValue: "Certificate expired")
        case .certificateInvalid:
            return String(localized: "vanta.error.title.certificateInvalid", defaultValue: "Certificate invalid")
        case .profileExpired:
            return String(
                localized: "vanta.error.title.profileExpired",
                defaultValue: "Provisioning profile expired"
            )
        case .profileMismatch:
            return String(localized: "vanta.error.title.profileMismatch", defaultValue: "Signing failed")
        case .entitlementsMismatch:
            return String(
                localized: "vanta.error.title.entitlementsMismatch",
                defaultValue: "Entitlements mismatch"
            )
        case .signerUnavailable:
            return String(localized: "vanta.error.title.signerUnavailable", defaultValue: "Signer unavailable")
        case .signingFailed:
            return String(localized: "vanta.error.title.signingFailed", defaultValue: "Signing failed")
        case .verificationFailed:
            return String(localized: "vanta.error.title.verificationFailed", defaultValue: "Verification failed")
        case .installationUnavailable:
            return String(
                localized: "vanta.error.title.installationUnavailable",
                defaultValue: "Installation unavailable"
            )
        case .refreshUnavailable:
            return String(localized: "vanta.error.title.refreshUnavailable", defaultValue: "Refresh unavailable")
        case .repositoryInvalid:
            return String(localized: "vanta.error.title.repositoryInvalid", defaultValue: "Repository invalid")
        case .backupFailed:
            return String(localized: "vanta.error.title.backupFailed", defaultValue: "Backup failed")
        case .keychainFailure:
            return String(localized: "vanta.error.title.keychainFailure", defaultValue: "Secure storage failed")
        case .notAvailable:
            return String(localized: "vanta.error.title.notAvailable", defaultValue: "Not available")
        }
    }

    /// Detailed reason (localized format strings; English defaults unchanged).
    public var reason: String {
        switch self {
        case .invalidURL(let value):
            return vantaFormat("vanta.error.reason.invalidURL", defaultValue: "“%@” is not a valid URL.", value)
        case .insecureURL(let url):
            return vantaFormat("vanta.error.reason.insecureURL",
                               defaultValue: "%@ uses plain HTTP. Use HTTPS or confirm explicitly.",
                               url.host ?? url.absoluteString)
        case .ipaNotFound:
            return String(localized: "vanta.error.reason.ipaNotFound",
                          defaultValue: "The IPA file could not be located.")
        case .ipaCorrupt(let detail):
            return detail
        case .infoPlistMissing:
            return String(localized: "vanta.error.reason.infoPlistMissing",
                          defaultValue: "No Info.plist was found inside Payload/*.app.")
        case .unsupportedArchitecture(let arch):
            return vantaFormat("vanta.error.reason.unsupportedArchitecture",
                               defaultValue: "Architecture “%@” is not supported on this device.", arch)
        case .certificateExpired(let name, let date):
            return vantaFormat("vanta.error.reason.certificateExpired",
                               defaultValue: "“%@” expired on %@. Import a current identity.",
                               name, vantaDate(date))
        case .certificateInvalid(let detail):
            return detail
        case .profileExpired(let name, let date):
            return vantaFormat("vanta.error.reason.profileExpired",
                               defaultValue: "“%@” expired on %@.", name, vantaDate(date))
        case .profileMismatch(let bundleID, let profile):
            let format = String(
                localized: "vanta.error.reason.profileMismatch",
                defaultValue: "The selected provisioning profile does not match this Bundle Identifier."
            )
            return format + "\nBundle ID: \(bundleID)\nProvisioning Profile: \(profile)"
        case .entitlementsMismatch(let missing):
            return vantaFormat("vanta.error.reason.entitlementsMismatch",
                               defaultValue: "Missing entitlements: %@. Choose a profile that grants them.",
                               missing.joined(separator: ", "))
        case .signerUnavailable(let detail):
            return detail
        case .signingFailed(let detail):
            return detail
        case .verificationFailed(let detail):
            return detail
        case .installationUnavailable(let detail):
            return detail
        case .refreshUnavailable(let detail):
            return detail
        case .repositoryInvalid(let detail):
            return detail
        case .backupFailed(let detail):
            return detail
        case .keychainFailure(let detail):
            return detail
        case .notAvailable(let detail):
            return detail
        }
    }

    /// Suggested user action label.
    public var remedy: String {
        switch self {
        case .profileMismatch:
            return String(localized: "vanta.error.remedy.profileMismatch", defaultValue: "Choose another profile")
        case .insecureURL:
            return String(localized: "vanta.error.remedy.insecureURL", defaultValue: "Use HTTPS")
        case .certificateExpired, .profileExpired:
            return String(localized: "vanta.error.remedy.expired", defaultValue: "Replace certificate")
        case .signerUnavailable, .installationUnavailable, .refreshUnavailable, .notAvailable:
            return String(localized: "vanta.error.remedy.requirements", defaultValue: "View requirements")
        default:
            return String(localized: "vanta.error.remedy.default", defaultValue: "Try again")
        }
    }

    // MARK: - LocalizedError

    /// Short description (title only).
    public var errorDescription: String? { self.title }

    /// Detailed reason.
    public var failureReason: String? { self.reason }

    /// Suggested recovery.
    public var recoverySuggestion: String? { self.remedy }
}

/// Localized format helper with an English default.
/// Resolves through the main bundle (String Catalog when present).
private func vantaFormat(
    _ key: String,
    defaultValue: String,
    _ args: CVarArg...
) -> String {
    let format = Bundle.main.localizedString(forKey: key, value: defaultValue, table: nil)
    return String(format: format, locale: Locale.current, arguments: args)
}

/// Locale-aware short date for error messages.
private func vantaDate(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .omitted)
}
