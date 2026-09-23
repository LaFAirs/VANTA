import SwiftUI

/// Honest refresh center: shows real expiries, never invents dates.
struct RefreshCenterView: View {
    /// Compact rendering for the dashboard.
    var compact = false
    @State private var apps: [ManagedApp] = []
    @State private var error: VantaError?
    @State private var busy = false

    var body: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Refresh").font(.headline)
                    Spacer()
                    if let next = self.nextExpiry {
                        Text("Next: \(next.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(VantaDS.secondaryText)
                    } else {
                        Text("No expiries tracked").font(.caption).foregroundStyle(VantaDS.secondaryText)
                    }
                }
                Text("\(self.needing.count) app(s) requiring refresh")
                    .font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                if let error {
                    Text(error.reason).font(.caption).foregroundStyle(VantaDS.warning)
                }
                HStack(spacing: 10) {
                    Button(self.busy ? "Refreshing…" : "Refresh All") {
                        Task { await self.refreshAll() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(VantaDS.accent)
                    .disabled(self.busy || self.needing.isEmpty)
                    if !self.compact {
                        NavigationLink("Certificates") { CertificatesView() }
                            .font(.subheadline).foregroundStyle(VantaDS.accent)
                    }
                }
                if !self.compact {
                    ForEach(self.needing.prefix(5)) { app in
                        HStack {
                            Text(app.name).font(.subheadline).lineLimit(1)
                            Spacer()
                            Button("Refresh") { Task { await self.refreshOne(app) } }
                                .font(.caption).foregroundStyle(VantaDS.accent)
                        }
                    }
                }
            }
        }
        .task { self.apps = await ManagedAppStore.shared.all() }
    }

    private var needing: [ManagedApp] {
        self.apps.filter { $0.status == .needsRefresh || $0.status == .expired }
    }

    private var nextExpiry: Date? { self.needing.compactMap(\.expiresAt).sorted().first }

    private func refreshAll() async {
        self.busy = true
        self.error = nil
        let certs = await CertificateStore.shared.activeCertificates()
        guard !certs.isEmpty else {
            self.error = .refreshUnavailable(reason: "No active certificate available. Import a valid .p12 first.")
            self.busy = false
            return
        }
        for app in self.needing {
            await ManagedAppStore.shared.markRefresh(
                bundleID: app.bundleID,
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
        }
        self.apps = await ManagedAppStore.shared.all()
        await Logger.shared.log(.success, "Refreshed \(self.needing.count) app(s)")
        self.busy = false
    }

    private func refreshOne(_ app: ManagedApp) async {
        await ManagedAppStore.shared.markRefresh(
            bundleID: app.bundleID,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        self.apps = await ManagedAppStore.shared.all()
    }
}
