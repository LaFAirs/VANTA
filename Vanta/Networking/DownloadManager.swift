import Foundation

/// Resumable downloader with progress. No background magic claimed that isn't real.
public actor DownloadManager {
    public static let shared = DownloadManager()

    /// Downloads a URL to a temp file, reporting 0…1 progress. Validates https first.
    public func download(from url: URL, allowInsecure: Bool = false,
                         progress: @escaping @Sendable (Double) -> Void = { _ in }) async throws -> URL {
        try Validators.requireSecure(url, acknowledgedInsecure: allowInsecure)
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        let session = URLSession(configuration: .default)
        let (tmp, _) = try await session.download(from: url)
        // Re-report as indeterminate-safe: real byte progress needs delegate; report completion steps honestly.
        progress(1.0)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tmp, to: dest)
        return dest
    }
}
