import Foundation

/// Pure, testable validators. No I/O, no singletons.
public enum Validators {
    private static let bundlePattern = #"^[A-Za-z][A-Za-z0-9\-]*(\.[A-Za-z][A-Za-z0-9\-]*)+$"#

    public static func isValidBundleID(_ s: String) -> Bool {
        s.range(of: bundlePattern, options: .regularExpression) != nil && s.count <= 155
    }

    public static func isValidVersion(_ s: String) -> Bool {
        !s.isEmpty && s.allSatisfy { $0.isNumber || $0 == "." } && !s.hasPrefix(".") && !s.hasSuffix(".")
    }

    public static func parseURL(_ raw: String) throws -> URL {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let u = URL(string: t), let scheme = u.scheme?.lowercased(),
              ["https", "http"].contains(scheme), u.host != nil else {
            throw VantaError.invalidURL(raw)
        }
        return u
    }

    /// Throws `.insecureURL` for http unless explicitly acknowledged.
    public static func requireSecure(_ url: URL, acknowledgedInsecure: Bool = false) throws {
        if url.scheme?.lowercased() == "http", !acknowledgedInsecure {
            throw VantaError.insecureURL(url)
        }
    }

    public static func isExpired(_ date: Date, now: Date = Date()) -> Bool { date <= now }

    public static func daysUntil(_ date: Date, now: Date = Date()) -> Int {
        Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
    }
}
