import Foundation

/// Scoped on-device storage: IPAs / Certificates / Profiles / Downloads / Backups / Logs.
public actor VantaFileStore {
    public enum Area: String, CaseIterable {
        case ipas = "IPAs", certificates = "Certificates", profiles = "Profiles",
             downloads = "Downloads", backups = "Backups", logs = "Logs"
    }
    public struct Item: Identifiable, Sendable {
        public var id: URL { url }
        public var url: URL
        public var size: Int64
        public init(url: URL, size: Int64) { self.url = url; self.size = size }
    }

    public static let shared = VantaFileStore()

    private func dir(_ area: Area) throws -> URL {
        let base = try FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Vanta", isDirectory: true)
            .appendingPathComponent(area.rawValue, isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    public func list(_ area: Area) throws -> [Item] {
        let d = try dir(area)
        let urls = (try? FileManager.default.contentsOfDirectory(at: d, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return urls.map {
            let size = (try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap(Int64.init) ?? 0
            return Item(url: $0, size: size)
        }.sorted { $0.url.lastPathComponent < $1.url.lastPathComponent }
    }

    public func delete(_ url: URL) throws { try FileManager.default.removeItem(at: url) }

    public func rename(_ url: URL, to name: String) throws -> URL {
        let dest = url.deletingLastPathComponent().appendingPathComponent(name)
        try FileManager.default.moveItem(at: url, to: dest)
        return dest
    }
}
