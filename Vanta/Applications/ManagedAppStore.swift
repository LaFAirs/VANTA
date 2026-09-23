import Foundation

/// Source of truth for managed apps. Actor → no data races.
public actor ManagedAppStore {
    public static let shared = ManagedAppStore()
    private var apps: [ManagedApp] = []
    private var activity: [ActivityEvent] = []

    public func all() -> [ManagedApp] { apps }
    public func needingRefresh() -> [ManagedApp] {
        apps.filter { $0.status == .needsRefresh || $0.status == .expired }
    }
    public func recentActivity(limit: Int = 8) -> [ActivityEvent] {
        Array(activity.suffix(limit).reversed())
    }

    public func upsert(_ app: ManagedApp) {
        if let i = apps.firstIndex(where: { $0.bundleID == app.bundleID }) {
            apps[i] = app
        } else {
            apps.append(app)
        }
        record("\(app.name) updated (\(app.version))")
    }

    public func remove(bundleID: String) {
        apps.removeAll { $0.bundleID == bundleID }
        record("Removed \(bundleID)")
    }

    public func markRefresh(bundleID: String, expiresAt: Date?) {
        guard let i = apps.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        apps[i].markRefreshed(expiresAt: expiresAt)
        record("\(apps[i].name) refreshed")
    }

    private func record(_ message: String) {
        activity.append(ActivityEvent(message: message))
        if activity.count > 200 { activity.removeFirst(activity.count - 200) }
    }
}
