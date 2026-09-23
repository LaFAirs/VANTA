import SwiftUI
import UniformTypeIdentifiers

/// Managed apps with refresh and uninstall actions.
struct AppsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var apps: [ManagedApp] = []
    @State private var error: VantaError?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let error { VantaErrorCard(error) }
                    if self.apps.isEmpty {
                        VantaCard {
                            VStack(spacing: 8) {
                                Text("No managed apps").font(.headline)
                                Text("Import an IPA to get started.")
                                    .font(.subheadline)
                                    .foregroundStyle(VantaDS.secondaryText)
                                VantaPrimaryButton("Import IPA") {
                                    self.appState.showingIPAImport = true
                                }
                            }
                        }
                    }
                    ForEach(self.apps) { app in
                        AppCard(
                            app: app,
                            onRefresh: { Task { await self.refresh(app) } },
                            onDelete: {
                                Task {
                                    await ManagedAppStore.shared.remove(bundleID: app.bundleID)
                                    await self.load()
                                }
                            },
                            onDetails: {}
                        )
                    }
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Apps")
            .toolbar {
                Button { self.appState.showingIPAImport = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: self.$appState.showingIPAImport) { ImportSheet() }
            .task { await self.load() }
        }
    }

    private func load() async {
        self.apps = await ManagedAppStore.shared.all()
    }

    private func refresh(_ app: ManagedApp) async {
        let certs = await CertificateStore.shared.activeCertificates()
        guard certs.first != nil else {
            self.error = .refreshUnavailable(reason: "No active certificate. Import a .p12 identity first.")
            return
        }
        await ManagedAppStore.shared.markRefresh(
            bundleID: app.bundleID,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        await self.load()
    }
}

/// Import entry: Files picker + URL download.
struct ImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlText = ""
    @State private var picking = false
    @State private var error: VantaError?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                if let error { VantaErrorCard(error) }
                VantaPrimaryButton(self.picking ? "Picking…" : "Choose IPA from Files") {
                    self.picking = true
                }
                .fileImporter(
                    isPresented: self.$picking,
                    allowedContentTypes: [.init(filenameExtension: "ipa") ?? .zip]
                ) { result in
                    Task {
                        switch result {
                        case .success(let url):
                            _ = await IPAImporter.shared.enqueueFile(at: url)
                            await Logger.shared.log(.success, "Queued \(url.lastPathComponent)")
                            self.dismiss()
                        case .failure(let caught):
                            self.error = .ipaCorrupt(reason: caught.localizedDescription)
                        }
                    }
                }
                HStack {
                    TextField("https://example.com/app.ipa", text: self.$urlText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("IPA download URL")
                    Button(self.busy ? "…" : "Get") { Task { await self.fetchURL() } }
                        .buttonStyle(.borderedProminent).tint(VantaDS.accent)
                }
                Spacer()
            }
            .padding()
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Import IPA")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func fetchURL() async {
        do {
            self.busy = true
            let url = try Validators.parseURL(self.urlText)
            _ = try await IPAImporter.shared.enqueueURL(url, allowInsecure: false)
            await Logger.shared.log(.success, "Downloaded \(url.lastPathComponent)")
            self.dismiss()
        } catch let caught as VantaError {
            self.error = caught
        } catch {
            self.error = .ipaCorrupt(reason: error.localizedDescription)
        }
        self.busy = false
    }
}
