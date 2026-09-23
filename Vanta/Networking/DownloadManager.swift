import Foundation

/// Downloader with honest progress. No background magic claimed that isn't real.
public actor DownloadManager {
    /// Shared instance.
    public static let shared = DownloadManager()

    /// Downloads a URL to a temp file, reporting 0…1 progress. Validates https first.
    public func download(
        from url: URL,
        allowInsecure: Bool = false,
        progress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws -> URL {
        try Validators.requireSecure(url, acknowledgedInsecure: allowInsecure)
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".ipa")
        let session = URLSession(configuration: .default)
        let (temporary, _) = try await session.download(from: url)
        // Real byte progress needs a delegate; report completion honestly instead.
        progress(1.0)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporary, to: destination)
        return destination
    }
}
