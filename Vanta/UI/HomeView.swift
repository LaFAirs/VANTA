import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var apps: [ManagedApp] = []
    @State private var certs: [SigningCertificate] = []
    @State private var activity: [ActivityEvent] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    deviceCard
                    statusRow
                    refreshCard
                    activityCard
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("VANTA")
            .toolbar {
                Button { appState.showingIPAImport = true } label: {
                    Label("Import IPA", systemImage: "plus")
                }.tint(VantaDS.accent)
            }
            .sheet(isPresented: $appState.showingIPAImport) { ImportSheet() }
            .task { await load() }
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
                row("Device", DeviceInfo.summary)
                row("VANTA", "\(DeveloperConfig.appVersion) (\(DeveloperConfig.buildNumber))")
                row("Managed apps", "\(apps.count)")
                row("Active certificates", "\(certs.filter { $0.status == .active }.count)")
            }
        }.accessibilityElement(children: .contain)
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            mini("Apps", "\(apps.count)", "square.stack.3d.up.fill")
            mini("Certs", "\(certs.count)", "key.fill")
            mini("Refresh", "\(apps.filter { $0.status == .needsRefresh || $0.status == .expired }.count)", "arrow.clockwise.circle.fill")
        }
    }

    private func mini(_ k: String, _ v: String, _ icon: String) -> some View {
        VantaCard {
            VStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(VantaDS.accent)
                Text(v).font(.title2).bold()
                Text(k).font(.caption).foregroundStyle(VantaDS.secondaryText)
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
                if activity.isEmpty {
                    Text("No activity yet.").font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                }
                ForEach(activity.prefix(5)) { e in
                    HStack {
                        Text(e.message).font(.subheadline).lineLimit(1)
                        Spacer()
                        Text(e.date, style: .time).font(.caption).foregroundStyle(VantaDS.secondaryText)
                    }
                }
            }
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundStyle(VantaDS.secondaryText); Spacer(); Text(v).fontWeight(.medium) }
            .font(.subheadline)
    }

    private func load() async {
        apps = await ManagedAppStore.shared.all()
        certs = await CertificateStore.shared.certificatesList()
        activity = await ManagedAppStore.shared.recentActivity()
    }
}
