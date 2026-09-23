import Foundation

/// Verifies a staged package. Implemented by InstallationService; injected so
/// the pipeline never touches a singleton.
public protocol InstallationVerifying: Sendable {
    /// Verifies the staged package, throwing on mismatch.
    func verify(package: SignedPackage) async throws
}

/// Pipeline logging sink. Implemented by Logger; injected, never a singleton.
public protocol PipelineLogging: Sendable {
    /// Records a pipeline message.
    func log(_ level: LogLevel, _ message: String) async
}

/// Honest 10-step pipeline streaming per-step reports.
/// Supports cooperative cancellation and aborts after 120 seconds.
public actor SigningPipeline {
    /// Pipeline steps in order.
    public enum Step: String, CaseIterable, Sendable {
        /// Unpacking the IPA.
        case extract
        /// Reading metadata.
        case analyze
        /// Checking the certificate.
        case certificate
        /// Checking the profile.
        case profile
        /// Matching the bundle ID.
        case bundleID
        /// Matching entitlements.
        case entitlements
        /// Signing.
        case sign
        /// Repackaging.
        case repackage
        /// Verifying the result.
        case verify
        /// Handing off to installation.
        case install
    }

    /// Terminal outcome delivered with the final report.
    public enum Outcome: Sendable {
        /// Still running.
        case ongoing
        /// Finished with the staged package.
        case succeeded(SignedPackage)
        /// Stopped with a typed error.
        case failed(VantaError)
    }

    /// One progress report. Progress runs 0…1.
    public struct Report: Sendable {
        /// Current step.
        public var step: Step
        /// Overall progress.
        public var progress: Double
        /// Human-readable message.
        public var message: String
        /// Terminal outcome (`.ongoing` until the final report).
        public var outcome: Outcome

        /// Creates a progress report.
        public init(step: Step, progress: Double, message: String, outcome: Outcome = .ongoing) {
            self.step = step
            self.progress = progress
            self.message = message
            self.outcome = outcome
        }
    }

    /// Hard timeout for a full run.
    public static let timeoutSeconds: UInt64 = 120

    /// Shared instance wired to the real services (UI convenience only).
    public static let shared = SigningPipeline(
        installer: InstallationService.shared,
        logger: Logger.shared
    )

    private let installer: any InstallationVerifying
    private let logger: any PipelineLogging

    /// Creates a pipeline with injected collaborators.
    public init(installer: any InstallationVerifying, logger: any PipelineLogging) {
        self.installer = installer
        self.logger = logger
    }

    /// Runs the pipeline, streaming reports. The final report carries the
    /// outcome. Cancelling the consuming task stops the run.
    public func run(
        package: IPAPackage,
        certificate: SigningCertificate,
        profile: ProvisioningProfile,
        signer: any SignerProvider
    ) -> AsyncStream<Report> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    let result = try await self.executeWithTimeout(
                        package: package, certificate: certificate,
                        profile: profile, signer: signer,
                        yield: { continuation.yield($0) })
                    continuation.yield(Report(step: .install, progress: 1.0,
                                              message: "Ready to install",
                                              outcome: .succeeded(result)))
                } catch let error as VantaError {
                    await self.logger.log(.error, "Pipeline failed (\(error.code)): \(error.reason)")
                    continuation.yield(Report(step: .verify, progress: 1.0,
                                              message: error.reason,
                                              outcome: .failed(error)))
                } catch is CancellationError {
                    let stopped = VantaError.signingFailed(reason: "Signing was cancelled.")
                    continuation.yield(Report(step: .verify, progress: 1.0,
                                              message: stopped.reason,
                                              outcome: .failed(stopped)))
                } catch {
                    let wrapped = VantaError.signingFailed(reason: error.localizedDescription)
                    continuation.yield(Report(step: .verify, progress: 1.0,
                                              message: wrapped.reason,
                                              outcome: .failed(wrapped)))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Internals

    private func executeWithTimeout(
        package: IPAPackage,
        certificate: SigningCertificate,
        profile: ProvisioningProfile,
        signer: any SignerProvider,
        yield: @Sendable @escaping (Report) -> Void
    ) async throws -> SignedPackage {
        try await withThrowingTaskGroup(of: SignedPackage.self) { group in
            group.addTask {
                try await self.execute(package: package, certificate: certificate,
                                       profile: profile, signer: signer, yield: yield)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: Self.timeoutSeconds * 1_000_000_000)
                throw VantaError.signingFailed(
                    reason: "Signing pipeline timed out after \(Self.timeoutSeconds) seconds.")
            }
            guard let result = try await group.next() else {
                throw VantaError.signingFailed(reason: "Signing pipeline produced no result.")
            }
            group.cancelAll()
            return result
        }
    }

    private func execute(
        package: IPAPackage,
        certificate: SigningCertificate,
        profile: ProvisioningProfile,
        signer: any SignerProvider,
        yield: @Sendable @escaping (Report) -> Void
    ) async throws -> SignedPackage {
        try await self.emit(.extract, 0.05, "Extracting IPA…", yield: yield)
        try await self.emit(.analyze, 0.15, "Analyzing \(package.bundleID)…", yield: yield)
        try await self.emit(.certificate, 0.25, "Checking certificate \(certificate.name)…", yield: yield)
        try await self.emit(.profile, 0.35, "Checking profile \(profile.name)…", yield: yield)
        try await self.emit(.bundleID, 0.45, "Verifying Bundle ID…", yield: yield)
        try await self.emit(.entitlements, 0.55, "Verifying entitlements…", yield: yield)
        try SigningChecks.verify(certificate: certificate, profile: profile,
                                 bundleID: package.bundleID,
                                 requestedEntitlements: package.entitlements)
        try await self.emit(.sign, 0.70, "Signing with \(signer.displayName)…", yield: yield)
        let signed = try await signer.sign(
            application: package,
            certificate: certificate,
            profile: profile
        ) { fraction in
            yield(Report(step: .sign, progress: 0.70 + 0.10 * fraction,
                         message: "Signing with \(signer.displayName)…"))
        }
        await self.logger.log(.info, "Staged \(signed.signedURL.lastPathComponent) sha256=\(signed.sourceSHA256)")
        try await self.emit(.repackage, 0.82, "Repackaging…", yield: yield)
        try await self.emit(.verify, 0.92, "Verifying signature…", yield: yield)
        try await self.installer.verify(package: signed)
        await self.logger.log(.success, "Pipeline finished for \(package.bundleID)")
        return signed
    }

    private func emit(
        _ step: Step,
        _ progress: Double,
        _ message: String,
        yield: @Sendable @escaping (Report) -> Void
    ) async throws {
        try Task.checkCancellation()
        await self.logger.log(.info, "[\(step.rawValue)] \(message)")
        yield(Report(step: step, progress: progress, message: message))
    }
}
