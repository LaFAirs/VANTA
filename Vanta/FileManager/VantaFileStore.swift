import Foundation

/// Scoped on-device storage: IPAs / Certificates / Profiles / Downloads / Backups / Logs.
public actor VantaFileStore {
    /// Storage area.
    public enum Area: String, CaseIterable {
        /// Imported IPA files.
        case ipas = "IPAs"
        /// Imported identities.
        case certificates = "Certificates"
        /// Imported profiles.
        case profiles = "Profiles"
        /// Downloads.
        case downloads = "Downloads"
        /// Backup files.
        case backups = "Backups"
        /// Exported logs.
        case logs = "Logs"
    }

    /// A stored file with its size.
    public struct Item: Identifiable, Sendable {
        /// File URL (stable identity).
        public var id: URL { self.url }
        /// File URL.
        public var url: URL
        /// File size in bytes.
        public var size: Int64

        /// Creates an item.
        public init(url: URL, size: Int64) {
            self.url = url
            self.size = size
        }
    }

    /// Shared instance.
    public static let shared = VantaFileStore()

    private func dir(_ area: Area) throws -> URL {
        let base = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("Vanta", isDirectory: true)
        .appendingPathComponent(area.rawValue, isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    /// Lists files in an area, sorted by name.
    public func list(_ area: Area) throws -> [Item] {
        let directory = try self.dir(area)
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey]
        )) ?? []
        return urls.map { url in
            let byteCount = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize)
                .flatMap(Int64.init) ?? 0
            return Item(url: url, size: byteCount)
        }.sorted { $0.url.lastPathComponent < $1.url.lastPathComponent }
    }

    /// Deletes a file.
    public func delete(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    /// Renames a file, returning its new URL.
    public func rename(_ url: URL, to name: String) throws -> URL {
        let destination = url.deletingLastPathComponent().appendingPathComponent(name)
        try FileManager.default.moveItem(at: url, to: destination)
        return destination
    }
}
