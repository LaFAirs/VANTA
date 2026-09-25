import Foundation

/// Versioned on-disk cache for compiled pipeline descriptors, keyed by a
/// content hash. Stores data blobs only; Metal objects are rebuilt at
/// launch and re-cached. Cache misses compile synchronously on first use.
final class ShaderCacheStore: @unchecked Sendable {
    private let lock = NSLock()
    private let manager = FileManager.default
    private let version = "v1"

    private var hits: Int = 0
    private var misses: Int = 0

    func cacheDirectory() throws -> URL {
        let base = try self.manager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = base.appendingPathComponent("ShaderCache-\(self.version)", isDirectory: true)
        try self.manager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func lookup(key: String) -> Data? {
        guard let url = try? self.cacheDirectory().appendingPathComponent(self.fileName(for: key)),
              let data = try? Data(contentsOf: url) else {
            self.lock.lock()
            self.misses += 1
            self.lock.unlock()
            return nil
        }
        self.lock.lock()
        self.hits += 1
        self.lock.unlock()
        return data
    }

    func store(key: String, data: Data) {
        guard let url = try? self.cacheDirectory().appendingPathComponent(self.fileName(for: key)) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func clear() {
        guard let directory = try? self.cacheDirectory() else { return }
        try? self.manager.removeItem(at: directory)
        self.lock.lock()
        self.hits = 0
        self.misses = 0
        self.lock.unlock()
    }

    func statistics() -> (hits: Int, misses: Int, entryCount: Int) {
        self.lock.lock()
        defer { self.lock.unlock() }
        let count = (try? self.manager.contentsOfDirectory(atPath: (try? self.cacheDirectory().path) ?? ""))?.count ?? 0
        return (self.hits, self.misses, count)
    }

    private func fileName(for key: String) -> String {
        let safe = key.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return String(safe.prefix(64)) + ".bin"
    }
}
