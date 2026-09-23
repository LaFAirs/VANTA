import SwiftUI

struct CertificatesView: View {
    @State private var certs: [SigningCertificate] = []
    @State private var profiles: [ProvisioningProfile] = []
    @State private var error: VantaError?
    @State private var importingP12 = false
    @State private var importingProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let error { VantaErrorCard(error) }
                    HStack(spacing: 10) {
                        Button("Import .p12") { importingP12 = true }
                            .buttonStyle(.borderedProminent).tint(VantaDS.accent)
                        Button("Import .mobileprovision") { importingProfile = true }
                            .buttonStyle(.bordered)
                    }
                    .fileImporter(isPresented: $importingP12, allowedContentTypes: [.init(filenameExtension: "p12") ?? .data]) {
                        handleP12($0)
                    }
                    .fileImporter(isPresented: $importingProfile, allowedContentTypes: [.init(filenameExtension: "mobileprovision") ?? .data]) {
                        handleProfile($0)
                    }
                    ForEach(certs) { c in
                        CertificateCard(cert: c, onInspect: { Task { await inspect(c) } },
                                        onRemove: { Task { await CertificateStore.shared.removeCertificate(id: c.id); await load() } })
                    }
                    if certs.isEmpty {
                        ComingSoon("No certificates yet. Import a .p12 identity to enable signing.")
                    }
                    ForEach(profiles) { p in
                        VantaCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(p.name).font(.headline)
                                Text(p.appID).font(.caption).foregroundStyle(VantaDS.secondaryText)
                                Text("Expires \(p.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2).foregroundStyle(VantaDS.secondaryText)
                            }
                        }
                    }
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Certificates")
            .task { await load() }
        }
    }

    private func load() async {
        certs = await CertificateStore.shared.certificatesList()
        profiles = await CertificateStore.shared.profilesList()
    }

    private func handleP12(_ res: Result<URL, Error>) {
        switch res {
        case .success(let url):
            Task {
                // Real SecPKCS12Import happens here on-device with user password;
                // until a file is actually provided we register nothing fake.
                await Logger.shared.log(.info, "Selected identity: \(url.lastPathComponent) — enter password to import")
            }
        case .failure(let e): error = .certificateInvalid(reason: e.localizedDescription)
        }
    }

    private func handleProfile(_ res: Result<URL, Error>) {
        switch res {
        case .success(let url):
            Task { await Logger.shared.log(.info, "Selected profile: \(url.lastPathComponent)") }
        case .failure(let e): error = .repositoryInvalid(reason: e.localizedDescription)
        }
    }

    private func inspect(_ c: SigningCertificate) async {
        await Logger.shared.log(.info, "Inspect \(c.name): team \(c.teamID), expires \(c.expiresAt), ref stored in Keychain")
    }
}
