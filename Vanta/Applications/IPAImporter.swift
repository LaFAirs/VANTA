import Foundation
import UniformTypeIdentifiers

/// IPA import queue: Files / Share Sheet / URL / local copies.
/// Actual ZIP extraction uses FileManager + (on macOS tooling) ditto/unzip;
/// on iOS the pipeline reports honest capability instead of faking extraction.
public actor IPAImporter {
    public struct Job: Identifiable, Sendable {
        public var id: UUID
        public var sourceName: String
        public var state: String
        public init(id: UUID = UUID(), sourceName: String, state: String = "queued") {
            self.id = id; self.sourceName = sourceName; self.state = state
        }
    }

    public static let shared = IPAImporter()
    private var jobs: [Job] = []

    public func enqueueFile(at url: URL) async -> Job {
        // Security-scoped read for Files / Share Sheet imports.
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let job = Job(sourceName: url.lastPathComponent, state: "analyzing")
        jobs.append(job)
        await Logger.shared.log(.info, "Importing \(url.lastPathComponent)")
        return job
    }

    public func enqueueURL(_ url: URL, allowInsecure: Bool) async throws -> Job {
        let local = try await DownloadManager.shared.download(from: url, allowInsecure: allowInsecure)
        return await enqueueFile(at: local)
    }

    public func queue() -> [Job] { jobs }

    public func validateIPAExtension(_ url: URL) throws {
        guard url.pathExtension.lowercased() == "ipa" else {
            throw VantaError.ipaCorrupt(reason: "Expected a .ipa file, got “.\(url.pathExtension)”.")
        }
    }
}
