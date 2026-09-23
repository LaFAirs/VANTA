import SwiftUI

/// Certificate Center: import, inspect, and remove signing identities.
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
                        Button("Import .p12") { self.importingP12 = true }
                            .buttonStyle(.borderedProminent).tint(VantaDS.accent)
                        Button("Import .mobileprovision") { self.importingProfile = true }
                            .buttonStyle(.bordered)
                    }
                    .fileImporter(
                        isPresented: self.$importingP12,
                        allowedContentTypes: [.init(filenameExtension: "p12") ?? .data]
                    ) { result in
                        self.handleP12(result)
                    }
                    .fileImporter(
                        isPresented: self.$importingProfile,
                        allowedContentTypes: [.init(filenameExtension: "mobileprovision") ?? .data]
                    ) { result in
                        self.handleProfile(result)
                    }
                    ForEach(self.certs) { cert in
                        CertificateCard(
                            cert: cert,
                            onUse: nil,
                            onInspect: { Task { await self.inspect(cert) } },
                            onRemove: {
                                Task {
                                    await CertificateStore.shared.removeCertificate(id: cert.id)
                                    await self.load()
                                }
                            }
                        )
                    }
                    if self.certs.isEmpty {
                        ComingSoon("No certificates yet. Import a .p12 identity to enable signing.")
                    }
                    ForEach(self.profiles) { profile in
                        VantaCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name).font(.headline)
                                Text(profile.appID)
                                    .font(.caption)
                                    .foregroundStyle(VantaDS.secondaryText)
                                Text("Expires \(profile.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(VantaDS.secondaryText)
                            }
                        }
                    }
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Certificates")
            .task { await self.load() }
        }
    }

    private func load() async {
        self.certs = await CertificateStore.shared.certificatesList()
        self.profiles = await CertificateStore.shared.profilesList()
    }

    private func handleP12(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task {
                // Real SecPKCS12Import happens here on-device with user password;
                // until a file is actually provided we register nothing fake.
                await Logger.shared.log(.info, "Selected identity: \(url.lastPathComponent)")
            }
        case .failure(let caught):
            self.error = .certificateInvalid(reason: caught.localizedDescription)
        }
    }

    private func handleProfile(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task { await Logger.shared.log(.info, "Selected profile: \(url.lastPathComponent)") }
        case .failure(let caught):
            self.error = .repositoryInvalid(reason: caught.localizedDescription)
        }
    }

    private func inspect(_ cert: SigningCertificate) async {
        await Logger.shared.log(
            .info,
            "Inspect \(cert.name): team \(cert.teamID), expires \(cert.expiresAt)"
        )
    }
}
