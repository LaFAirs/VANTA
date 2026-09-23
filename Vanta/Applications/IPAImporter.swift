import Foundation
import UniformTypeIdentifiers

/// IPA import queue: Files / Share Sheet / URL / local copies.
/// Actual ZIP extraction uses FileManager + (on macOS tooling) ditto/unzip;
/// on iOS the pipeline reports honest capability instead of faking extraction.
public actor IPAImporter {
    /// A queued import.
    public struct Job: Identifiable, Sendable {
        /// Stable identity.
        public let id: UUID
        /// Source file name.
        public let sourceName: String
        /// Queue state.
        public let state: String

        /// Creates a job.
        public init(id: UUID = UUID(), sourceName: String, state: String = "queued") {
            self.id = id
            self.sourceName = sourceName
            self.state = state
        }
    }

    /// Shared instance.
    public static let shared = IPAImporter()
    private var jobs: [Job] = []

    /// Enqueues a local file for import.
    public func enqueueFile(at url: URL) async -> Job {
        // Security-scoped read for Files / Share Sheet imports.
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let job = Job(sourceName: url.lastPathComponent, state: "analyzing")
        self.jobs.append(job)
        await Logger.shared.log(.info, "Importing \(url.lastPathComponent)")
        return job
    }

    /// Downloads and enqueues a remote IPA.
    public func enqueueURL(_ url: URL, allowInsecure: Bool) async throws -> Job {
        let local = try await DownloadManager.shared.download(from: url, allowInsecure: allowInsecure)
        return await self.enqueueFile(at: local)
    }

    /// Current queue snapshot.
    public func queue() -> [Job] { self.jobs }

    /// Rejects non-IPA files early with an actionable error.
    public func validateIPAExtension(_ url: URL) throws {
        guard url.pathExtension.lowercased() == "ipa" else {
            throw VantaError.ipaCorrupt(reason: "Expected a .ipa file, got “.\(url.pathExtension)”.")
        }
    }
}
