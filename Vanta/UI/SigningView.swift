import SwiftUI

/// Guided signing: pick a signer, certificate, and profile, then run the pipeline.
struct SigningView: View {
    /// The analyzed package to sign.
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
                self.analysisCard
                if let currentError = error { VantaErrorCard(currentError) { self.error = nil } }
                self.signerCard
                self.certCard
                self.profileCard
                PipelineProgressView(phase: self.phase, progress: self.progress)
                if !self.status.isEmpty {
                    Text(self.status).font(.caption).foregroundStyle(VantaDS.secondaryText)
                }
                VantaPrimaryButton(self.running ? "Signing…" : "Sign & Verify") {
                    Task { await self.run() }
                }
                .disabled(self.running || self.selectedCert == nil || self.selectedProfile == nil)
            }.padding()
        }
        .background(VantaDS.background.ignoresSafeArea())
        .navigationTitle("Signing")
        .task {
            self.certs = await CertificateStore.shared.certificatesList()
            self.profiles = await CertificateStore.shared.profilesList()
            self.selectedCert = self.certs.first
            self.selectedProfile = await CertificateStore.shared
                .eligibleProfiles(bundleID: self.package.bundleID).first
        }
    }

    private var analysisCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.package.name).font(.headline)
                Text(self.package.bundleID).font(.caption).foregroundStyle(VantaDS.secondaryText)
                Text(self.analysisSubtitle).font(.caption).foregroundStyle(VantaDS.secondaryText)
            }
        }
    }

    private var analysisSubtitle: String {
        let architectures = self.package.architectures.joined(separator: ", ")
        return "v\(self.package.version) (\(self.package.build)) · min \(self.package.minimumOS) · \(architectures)"
    }

    private var signerCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Signer").font(.headline)
                Picker("Signer", selection: self.$signerID) {
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
                Picker("Certificate", selection: self.$selectedCert) {
                    ForEach(self.certs) { cert in
                        Text("\(cert.name) (\(cert.teamID))").tag(Optional(cert))
                    }
                }
                if self.certs.isEmpty {
                    Text("No certificates — import a .p12 first.")
                        .font(.subheadline)
                        .foregroundStyle(VantaDS.warning)
                }
            }
        }
    }

    private var profileCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Provisioning profile").font(.headline)
                Picker("Profile", selection: self.$selectedProfile) {
                    ForEach(self.profiles) { profile in
                        Text(profile.name).tag(Optional(profile))
                    }
                }
                if self.profiles.isEmpty {
                    Text("No profiles — import a .mobileprovision first.")
                        .font(.subheadline)
                        .foregroundStyle(VantaDS.warning)
                }
            }
        }
    }

    private func signer() -> any SignerProvider {
        switch self.signerID {
        case "imported": return ImportedCertificateSigner()
        case "personal": return PersonalTeamSigner()
        case "remote": return RemoteSigner()
        default: return LocalCertificateSigner()
        }
    }

    private func run() async {
        guard let cert = selectedCert, let profile = selectedProfile else { return }
        let availability = self.signer().availability(certificate: cert, profile: profile)
        guard case .ready = availability else {
            self.error = .signerUnavailable(availability.reason ?? "Signer is not ready.")
            return
        }
        self.running = true
        self.error = nil
        self.phase = .processing
        var outcome: SigningPipeline.Outcome = .ongoing
        let stream = SigningPipeline.shared.run(
            package: self.package,
            certificate: cert,
            profile: profile,
            signer: self.signer()
        )
        for await report in stream {
            self.progress = report.progress
            self.status = report.message
            switch report.step {
            case .sign: self.phase = .signing
            case .verify: self.phase = .verifying
            case .install: self.phase = .installing
            default: self.phase = .processing
            }
            if report.progress >= 1.0 { self.phase = .success }
            outcome = report.outcome
        }
        switch outcome {
        case .succeeded(let staged):
            do {
                try await ManagedAppStore.shared.upsert(ManagedApp(
                    name: self.package.name,
                    bundleID: self.package.bundleID,
                    version: self.package.version,
                    build: self.package.build,
                    status: .installed,
                    teamID: cert.teamID
                ))
                await Logger.shared.log(.success, "Installed record for \(staged.original.bundleID)")
            } catch let updateError as VantaError {
                self.error = updateError
                self.phase = .idle
            } catch {
                self.error = .signingFailed(reason: error.localizedDescription)
                self.phase = .idle
            }
        case .failed(let pipelineError):
            self.error = pipelineError
            self.phase = .idle
        case .ongoing:
            self.error = .signingFailed(reason: "Signing pipeline ended without a result.")
            self.phase = .idle
        }
        self.running = false
    }
}

/// Picker support: certificates compare by identity.
extension SigningCertificate: Hashable {
    /// Hashes the identity.
    public func hash(into hasher: inout Hasher) { hasher.combine(self.id) }

    /// Compares identities.
    public static func == (lhs: SigningCertificate, rhs: SigningCertificate) -> Bool {
        lhs.id == rhs.id
    }
}

/// Picker support: profiles compare by identity.
extension ProvisioningProfile: Hashable {
    /// Hashes the identity.
    public func hash(into hasher: inout Hasher) { hasher.combine(self.id) }

    /// Compares identities.
    public static func == (lhs: ProvisioningProfile, rhs: ProvisioningProfile) -> Bool {
        lhs.id == rhs.id
    }
}
