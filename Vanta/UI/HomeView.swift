import SwiftUI

/// Home dashboard: device, certificates, refresh state, recent activity.
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var apps: [ManagedApp] = []
    @State private var certs: [SigningCertificate] = []
    @State private var activity: [ActivityEvent] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    self.deviceCard
                    self.statusRow
                    self.refreshCard
                    self.activityCard
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("VANTA")
            .toolbar {
                Button {
                    self.appState.showingIPAImport = true
                } label: {
                    Label("Import IPA", systemImage: "plus")
                }.tint(VantaDS.accent)
            }
            .sheet(isPresented: $appState.showingIPAImport) { ImportSheet() }
            .task { await self.load() }
        }
    }

    private var deviceCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("VANTA").font(.largeTitle).bold()
                    .foregroundStyle(.white)
                    .shadow(color: VantaDS.accentGlow, radius: 16)
                Text(DeveloperConfig.tagline).foregroundStyle(VantaDS.secondaryText)
                Divider().background(VantaDS.cardBorder)
                self.row("Device", DeviceInfo.summary)
                self.row("VANTA", "\(DeveloperConfig.appVersion) (\(DeveloperConfig.buildNumber))")
                self.row("Managed apps", "\(self.apps.count)")
                self.row(
                    "Active certificates",
                    "\(self.certs.filter { $0.status == .active }.count)"
                )
            }
        }.accessibilityElement(children: .contain)
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            self.mini("Apps", "\(self.apps.count)", "square.stack.3d.up.fill")
            self.mini("Certs", "\(self.certs.count)", "key.fill")
            self.mini(
                "Refresh",
                "\(self.apps.filter { $0.status == .needsRefresh || $0.status == .expired }.count)",
                "arrow.clockwise.circle.fill"
            )
        }
    }

    private func mini(_ title: String, _ value: String, _ icon: String) -> some View {
        VantaCard {
            VStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(VantaDS.accent)
                Text(value).font(.title2).bold()
                Text(title).font(.caption).foregroundStyle(VantaDS.secondaryText)
            }.frame(maxWidth: .infinity)
        }
    }

    private var refreshCard: some View {
        RefreshCenterView(compact: true)
    }

    private var activityCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent activity").font(.headline)
                if self.activity.isEmpty {
                    Text("No activity yet.").font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                }
                ForEach(self.activity.prefix(5)) { event in
                    HStack {
                        Text(event.message).font(.subheadline).lineLimit(1)
                        Spacer()
                        Text(event.date, style: .time)
                            .font(.caption)
                            .foregroundStyle(VantaDS.secondaryText)
                    }
                }
            }
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).foregroundStyle(VantaDS.secondaryText)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private func load() async {
        self.apps = await ManagedAppStore.shared.all()
        self.certs = await CertificateStore.shared.certificatesList()
        self.activity = await ManagedAppStore.shared.recentActivity()
    }
}
