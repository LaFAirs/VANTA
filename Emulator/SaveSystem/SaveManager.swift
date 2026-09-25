import Foundation

/// One user profile owning its own save-data directory.
struct SaveProfile: Sendable, Codable, Equatable, Identifiable {
    var id: UUID
    var name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

/// Local save-data manager: per-profile directories under Application
/// Support, with backup/restore and user-driven export. Saves never leave
/// the device except through an explicit user share/export action.
final class SaveManager: Sendable {
    private let lock = NSLock()
    private let manager = FileManager.default
    private let profilesKey = "switchemu.save.profiles"

    func savesRoot() throws -> URL {
        let base = try self.manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = base.appendingPathComponent("Saves", isDirectory: true)
        try self.manager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    func profiles() -> [SaveProfile] {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let data = UserDefaults.standard.data(forKey: self.profilesKey),
              let decoded = try? JSONDecoder().decode([SaveProfile].self, from: data) else {
            return [SaveProfile(name: "Player 1")]
        }
        return decoded
    }

    func addProfile(named name: String) throws -> SaveProfile {
        let profile = SaveProfile(name: name)
        var current = self.profiles()
        current.append(profile)
        try self.persist(current)
        try self.manager.createDirectory(at: self.directory(for: profile), withIntermediateDirectories: true)
        return profile
    }

    func writeSave(named slot: String, data: Data, for profile: SaveProfile) throws {
        let url = try self.directory(for: profile).appendingPathComponent("\(slot).sav")
        try data.write(to: url, options: .atomic)
    }

    func readSave(named slot: String, for profile: SaveProfile) throws -> Data {
        let url = try self.directory(for: profile).appendingPathComponent("\(slot).sav")
        return try Data(contentsOf: url)
    }

    func listSlots(for profile: SaveProfile) -> [String] {
        guard let directory = try? self.directory(for: profile) else { return [] }
        let items = (try? self.manager.contentsOfDirectory(atPath: directory.path)) ?? []
        return items.filter { $0.hasSuffix(".sav") }.sorted()
    }

    /// Copies the profile directory to a timestamped backup. Returns the URL.
    func backup(profile: SaveProfile) throws -> URL {
        let source = try self.directory(for: profile)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let target = try self.savesRoot().appendingPathComponent("\(profile.name)-\(stamp)", isDirectory: true)
        try self.manager.copyItem(at: source, to: target)
        Logger.shared.log(.info, subsystem: "Save", message: "Backup created for \(profile.name).")
        return target
    }

    private func directory(for profile: SaveProfile) throws -> URL {
        let directory = try self.savesRoot().appendingPathComponent(profile.id.uuidString, isDirectory: true)
        try self.manager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func persist(_ profiles: [SaveProfile]) throws {
        let data = try JSONEncoder().encode(profiles)
        self.lock.lock()
        UserDefaults.standard.set(data, forKey: self.profilesKey)
        self.lock.unlock()
    }
}
