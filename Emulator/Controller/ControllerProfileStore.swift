import Foundation

/// Persists controller profiles and the active selection as JSON in
/// UserDefaults. Ships with a single "Default" profile.
final class ControllerProfileStore: @unchecked Sendable {
    private let lock = NSLock()
    private let profilesKey = "switchemu.controller.profiles"
    private let activeKey = "switchemu.controller.active"

    func load() -> [ControllerProfile] {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let data = UserDefaults.standard.data(forKey: self.profilesKey),
              let decoded = try? JSONDecoder().decode([ControllerProfile].self, from: data),
              !decoded.isEmpty else {
            return [ControllerProfile(name: "Default")]
        }
        return decoded
    }

    func save(_ profiles: [ControllerProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        self.lock.lock()
        UserDefaults.standard.set(data, forKey: self.profilesKey)
        self.lock.unlock()
    }

    func loadActiveID(in profiles: [ControllerProfile]) -> UUID {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let saved = UserDefaults.standard.string(forKey: self.activeKey),
           let match = profiles.first(where: { $0.id.uuidString == saved }) {
            return match.id
        }
        return profiles[0].id
    }

    func saveActiveID(_ id: UUID) {
        self.lock.lock()
        UserDefaults.standard.set(id.uuidString, forKey: self.activeKey)
        self.lock.unlock()
    }
}
