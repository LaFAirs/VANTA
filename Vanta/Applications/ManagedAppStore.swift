import Foundation

/// Source of truth for managed apps. Actor → no data races.
public actor ManagedAppStore {
    /// Shared instance.
    public static let shared = ManagedAppStore()
    private var apps: [ManagedApp] = []
    private var activity: [ActivityEvent] = []

    /// All managed apps.
    public func all() -> [ManagedApp] { self.apps }

    /// Apps needing a refresh.
    public func needingRefresh() -> [ManagedApp] {
        self.apps.filter { $0.status == .needsRefresh || $0.status == .expired }
    }

    /// Recent activity, newest first.
    public func recentActivity(limit: Int = 8) -> [ActivityEvent] {
        Array(self.activity.suffix(limit).reversed())
    }

    /// Inserts or replaces an app by bundle ID.
    public func upsert(_ app: ManagedApp) {
        if let index = self.apps.firstIndex(where: { $0.bundleID == app.bundleID }) {
            self.apps[index] = app
        } else {
            self.apps.append(app)
        }
        self.record("\(app.name) updated (\(app.version))")
    }

    /// Removes an app by bundle ID.
    public func remove(bundleID: String) {
        self.apps.removeAll { $0.bundleID == bundleID }
        self.record("Removed \(bundleID)")
    }

    /// Marks an app refreshed with a new expiry.
    public func markRefresh(bundleID: String, expiresAt: Date?) {
        guard let index = self.apps.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        self.apps[index].markRefreshed(expiresAt: expiresAt)
        self.record("\(self.apps[index].name) refreshed")
    }

    private func record(_ message: String) {
        self.activity.append(ActivityEvent(message: message))
        if self.activity.count > 200 { self.activity.removeFirst(self.activity.count - 200) }
    }
}
