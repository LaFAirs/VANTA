import SwiftUI
import UniformTypeIdentifiers

struct AppsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var apps: [ManagedApp] = []
    @State private var error: VantaError?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let error { VantaErrorCard(error) }
                    if apps.isEmpty {
                        VantaCard {
                            VStack(spacing: 8) {
                                Text("No managed apps").font(.headline)
                                Text("Import an IPA to get started.").font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                                VantaPrimaryButton("Import IPA") { appState.showingIPAImport = true }
                            }
                        }
                    }
                    ForEach(apps) { app in
                        AppCard(app: app,
                                onRefresh: { Task { await refresh(app) } },
                                onDelete: { Task { await ManagedAppStore.shared.remove(bundleID: app.bundleID); await load() } },
                                onDetails: {})
                    }
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Apps")
            .toolbar {
                Button { appState.showingIPAImport = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $appState.showingIPAImport) { ImportSheet() }
            .task { await load() }
        }
    }

    private func load() async { apps = await ManagedAppStore.shared.all() }

    private func refresh(_ app: ManagedApp) async {
        let certs = await CertificateStore.shared.activeCertificates()
        guard certs.first != nil else {
            error = .refreshUnavailable(reason: "No active certificate. Import a .p12 identity first.")
            return
        }
        await ManagedAppStore.shared.markRefresh(bundleID: app.bundleID,
                                                 expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()))
        await load()
    }
}

/// Import entry: Files picker + URL download. Drag & Drop handled by `.dropDestination` on iPad.
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
                VantaPrimaryButton(picking ? "Picking…" : "Choose IPA from Files") {
                    picking = true
                }
                .fileImporter(isPresented: $picking, allowedContentTypes: [.init(filenameExtension: "ipa") ?? .zip]) { res in
                    Task {
                        switch res {
                        case .success(let url):
                            _ = await IPAImporter.shared.enqueueFile(at: url)
                            await Logger.shared.log(.success, "Queued \(url.lastPathComponent)")
                            dismiss()
                        case .failure(let e):
                            error = .ipaCorrupt(reason: e.localizedDescription)
                        }
                    }
                }
                HStack {
                    TextField("https://example.com/app.ipa", text: $urlText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("IPA download URL")
                    Button(busy ? "…" : "Get") { Task { await fetchURL() } }
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
            busy = true
            let url = try Validators.parseURL(urlText)
            _ = try await IPAImporter.shared.enqueueURL(url, allowInsecure: false)
            await Logger.shared.log(.success, "Downloaded \(url.lastPathComponent)")
            dismiss()
        } catch let e as VantaError { self.error = e }
        catch { self.error = .ipaCorrupt(reason: error.localizedDescription) }
        busy = false
    }
}
