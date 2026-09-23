import SwiftUI

struct SigningView: View {
    let package: IPAPackage
    @State private var certs: [SigningCertificate] = []
    @State private var profiles: [ProvisioningProfile] = []
    @State private var selectedCert: SigningCertificate?
    @State private var selectedProfile: ProvisioningProfile?
    @State private var signerID = "local"
    @State private var phase = PipelineProgressView.Phase.idle
    @State private var progress = 0.0
    @State private var status = ""
    @State private var error: VantaError?
    @State private var running = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                analysisCard
                if let e = error { VantaErrorCard(e) { self.error = nil } }
                signerCard
                certCard
                profileCard
                PipelineProgressView(phase: phase, progress: progress)
                if !status.isEmpty { Text(status).font(.caption).foregroundStyle(VantaDS.secondaryText) }
                VantaPrimaryButton(running ? "Signing…" : "Sign & Verify") { Task { await run() } }
                    .disabled(running || selectedCert == nil || selectedProfile == nil)
            }.padding()
        }
        .background(VantaDS.background.ignoresSafeArea())
        .navigationTitle("Signing")
        .task {
            certs = await CertificateStore.shared.certificatesList()
            profiles = await CertificateStore.shared.profilesList()
            selectedCert = certs.first
            selectedProfile = await CertificateStore.shared.eligibleProfiles(bundleID: package.bundleID).first
        }
    }

    private var analysisCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.name).font(.headline)
                Text(package.bundleID).font(.caption).foregroundStyle(VantaDS.secondaryText)
                Text("v\(package.version) (\(package.build)) · min \(package.minimumOS) · \(package.architectures.joined(separator: ", "))")
                    .font(.caption).foregroundStyle(VantaDS.secondaryText)
            }
        }
    }

    private var signerCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Signer").font(.headline)
                Picker("Signer", selection: $signerID) {
                    Text("Local Certificate").tag("local")
                    Text("Imported Certificate").tag("imported")
                    Text("Personal Team").tag("personal")
                    Text("Remote").tag("remote")
                }.pickerStyle(.segmented)
            }
        }
    }

    private var certCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Certificate").font(.headline)
                Picker("Certificate", selection: $selectedCert) {
                    ForEach(certs) { c in Text("\(c.name) (\(c.teamID))").tag(Optional(c)) }
                }
                if certs.isEmpty { Text("No certificates — import a .p12 first.").font(.subheadline).foregroundStyle(VantaDS.warning) }
            }
        }
    }

    private var profileCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Provisioning profile").font(.headline)
                Picker("Profile", selection: $selectedProfile) {
                    ForEach(profiles) { p in Text(p.name).tag(Optional(p)) }
                }
                if profiles.isEmpty { Text("No profiles — import a .mobileprovision first.").font(.subheadline).foregroundStyle(VantaDS.warning) }
            }
        }
    }

    private func signer() -> any SignerProvider {
        switch signerID {
        case "imported": return ImportedCertificateSigner()
        case "personal": return PersonalTeamSigner()
        case "remote": return RemoteSigner()
        default: return LocalCertificateSigner()
        }
    }

    private func run() async {
        guard let cert = selectedCert, let profile = selectedProfile else { return }
        running = true; error = nil; phase = .processing
        do {
            _ = try await SigningPipeline.shared.run(
                package: package, certificate: cert, profile: profile, signer: signer()
            ) { report in
                Task { @MainActor in
                    self.progress = report.progress
                    self.status = report.message
                    switch report.step {
                    case .sign: self.phase = .signing
                    case .verify: self.phase = .verifying
                    case .install: self.phase = .installing
                    default: self.phase = .processing
                    }
                    if report.progress >= 1.0 { self.phase = .success }
                }
            }
            await ManagedAppStore.shared.upsert(ManagedApp(name: package.name, bundleID: package.bundleID,
                                                           version: package.version, build: package.build,
                                                           status: .installed, teamID: cert.teamID))
        } catch let e as VantaError { self.error = e; phase = .idle }
        catch { self.error = .signingFailed(reason: error.localizedDescription); phase = .idle }
        running = false
    }
}

extension SigningCertificate: Hashable {
    public func hash(into h: inout Hasher) { h.combine(id) }
    public static func == (l: SigningCertificate, r: SigningCertificate) -> Bool { l.id == r.id }
}
extension ProvisioningProfile: Hashable {
    public func hash(into h: inout Hasher) { h.combine(id) }
    public static func == (l: ProvisioningProfile, r: ProvisioningProfile) -> Bool { l.id == r.id }
}
