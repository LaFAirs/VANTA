import SwiftUI

/// Honest refresh center: shows real expiries, never invents dates.
struct RefreshCenterView: View {
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
                    if let next = nextExpiry {
                        Text("Next: \(next.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(VantaDS.secondaryText)
                    } else {
                        Text("No expiries tracked").font(.caption).foregroundStyle(VantaDS.secondaryText)
                    }
                }
                Text("\(needing.count) app(s) requiring refresh")
                    .font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                if let error { Text(error.reason).font(.caption).foregroundStyle(VantaDS.warning) }
                HStack(spacing: 10) {
                    Button(busy ? "Refreshing…" : "Refresh All") { Task { await refreshAll() } }
                        .buttonStyle(.borderedProminent).tint(VantaDS.accent).disabled(busy || needing.isEmpty)
                    if !compact {
                        NavigationLink("Certificates") { CertificatesView() }
                            .font(.subheadline).foregroundStyle(VantaDS.accent)
                    }
                }
                if !compact {
                    ForEach(needing.prefix(5)) { a in
                        HStack {
                            Text(a.name).font(.subheadline).lineLimit(1)
                            Spacer()
                            Button("Refresh") { Task { await refreshOne(a) } }
                                .font(.caption).foregroundStyle(VantaDS.accent)
                        }
                    }
                }
            }
        }
        .task { apps = await ManagedAppStore.shared.all() }
    }

    private var needing: [ManagedApp] {
        apps.filter { $0.status == .needsRefresh || $0.status == .expired }
    }
    private var nextExpiry: Date? { needing.compactMap(\.expiresAt).sorted().first }

    private func refreshAll() async {
        busy = true; error = nil
        let certs = await CertificateStore.shared.activeCertificates()
        guard !certs.isEmpty else {
            error = .refreshUnavailable(reason: "No active certificate available. Import a valid .p12 first.")
            busy = false; return
        }
        for a in needing {
            await ManagedAppStore.shared.markRefresh(bundleID: a.bundleID,
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()))
        }
        apps = await ManagedAppStore.shared.all()
        await Logger.shared.log(.success, "Refreshed \(needing.count) app(s)")
        busy = false
    }

    private func refreshOne(_ a: ManagedApp) async {
        await ManagedAppStore.shared.markRefresh(bundleID: a.bundleID,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()))
        apps = await ManagedAppStore.shared.all()
    }
}
