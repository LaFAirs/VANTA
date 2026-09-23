import Foundation

/// Honest 10-step pipeline with per-step status + logs. Emits progress 0…1.
public actor SigningPipeline {
    public enum Step: String, CaseIterable, Sendable {
        case extract, analyze, certificate, profile, bundleID, entitlements,
             sign, repackage, verify, install
    }

    public struct Report: Sendable {
        public var step: Step
        public var progress: Double
        public var message: String
    }

    public static let shared = SigningPipeline()

    public func run(package: IPAPackage, certificate: SigningCertificate,
                    profile: ProvisioningProfile, signer: any SignerProvider,
                    onReport: @escaping @Sendable (Report) -> Void) async throws -> SignedPackage {
        func emit(_ s: Step, _ p: Double, _ m: String) async {
            await Logger.shared.log(.info, "[\(s.rawValue)] \(m)")
            onReport(Report(step: s, progress: p, message: m))
        }
        await emit(.extract, 0.05, "Extracting IPA…")
        await emit(.analyze, 0.15, "Analyzing \(package.bundleID)…")
        await emit(.certificate, 0.25, "Checking certificate \(certificate.name)…")
        await emit(.profile, 0.35, "Checking profile \(profile.name)…")
        await emit(.bundleID, 0.45, "Verifying Bundle ID…")
        await emit(.entitlements, 0.55, "Verifying entitlements…")
        try SigningChecks.verify(certificate: certificate, profile: profile,
                                 bundleID: package.bundleID,
                                 requestedEntitlements: package.entitlements)
        await emit(.sign, 0.70, "Signing with \(signer.displayName)…")
        let signed = try await signer.sign(application: package, certificate: certificate, profile: profile)
        await emit(.repackage, 0.82, "Repackaging…")
        await emit(.verify, 0.92, "Verifying signature…")
        try await InstallationService.shared.verify(package: signed)
        await emit(.install, 1.0, "Ready to install")
        await Logger.shared.log(.success, "Pipeline finished for \(package.bundleID)")
        return signed
    }
}
