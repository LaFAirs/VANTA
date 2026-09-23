import Foundation

/// Pure, testable validators. No I/O, no singletons.
public enum Validators {
    private static let bundlePattern = #"^[A-Za-z][A-Za-z0-9\-]*(\.[A-Za-z][A-Za-z0-9\-]*)+$"#

    /// True for reverse-DNS bundle identifiers.
    public static func isValidBundleID(_ value: String) -> Bool {
        value.range(of: bundlePattern, options: .regularExpression) != nil && value.count <= 155
    }

    /// True for dotted numeric versions like 1.2.3.
    public static func isValidVersion(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isNumber || $0 == "." }
            && !value.hasPrefix(".") && !value.hasSuffix(".")
    }

    /// Parses an http(s) URL or throws.
    public static func parseURL(_ raw: String) throws -> URL {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let candidate = URL(string: trimmed),
              let scheme = candidate.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              candidate.host != nil else {
            throw VantaError.invalidURL(raw)
        }
        return candidate
    }

    /// Throws `.insecureURL` for http unless explicitly acknowledged.
    public static func requireSecure(_ url: URL, acknowledgedInsecure: Bool = false) throws {
        if url.scheme?.lowercased() == "http", !acknowledgedInsecure {
            throw VantaError.insecureURL(url)
        }
    }

    /// True when the date is past.
    public static func isExpired(_ date: Date, now: Date = Date()) -> Bool { date <= now }

    /// Whole days from now until the date.
    public static func daysUntil(_ date: Date, now: Date = Date()) -> Int {
        Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
    }
}
