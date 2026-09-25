import Foundation

/// Sandbox-safe file import. Files are chosen by the user via the system
/// document picker (`.fileImporter` in the UI) and copied into the app
/// sandbox. Security-scoped bookmarks persist access across launches.
/// Hard limits, honestly enforced:
/// - Only raw demo binaries (`.bin`) up to 8 MiB are accepted.
/// - No container parsing, no decryption, no key handling, no downloads.
/// - Anything else is rejected with a user-facing error, never a crash.
enum SandboxFSError: Error, Sendable, Equatable {
    case accessDenied
    case tooLarge(maxBytes: Int)
    case unsupportedType
    case copyFailed
    case bookmarkFailed
}

struct ImportedFile: Sendable, Equatable {
    let id: UUID
    let displayName: String
    let sizeBytes: Int
    let storedURL: URL
    let importedAt: Date
}

final class SandboxFS: @unchecked Sendable {
    static let maxImportBytes = 8 * 1024 * 1024
    static let allowedExtensions: Set<String> = ["bin"]

    private let lock = NSLock()
    private let manager = FileManager.default
    private let bookmarkKey = "switchemu.bookmarks"

    func libraryDirectory() throws -> URL {
        let base = try self.manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let library = base.appendingPathComponent("Library", isDirectory: true)
        try self.manager.createDirectory(at: library, withIntermediateDirectories: true)
        return library
    }

    /// Validates and copies a user-picked file into the sandbox library.
    func importFile(from url: URL) throws -> ImportedFile {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        let size = values.fileSize ?? 0
        guard size > 0, size <= Self.maxImportBytes else {
            throw SandboxFSError.tooLarge(maxBytes: Self.maxImportBytes)
        }
        guard Self.allowedExtensions.contains(url.pathExtension.lowercased()) else {
            throw SandboxFSError.unsupportedType
        }
        let library = try self.libraryDirectory()
        let stored = library.appendingPathComponent("\(UUID().uuidString).bin")
        do {
            if accessing {
                try self.manager.copyItem(at: url, to: stored)
            } else {
                try self.manager.copyItem(at: url, to: stored)
            }
        } catch {
            throw SandboxFSError.copyFailed
        }
        self.storeBookmark(for: stored)
        Logger.shared.log(.info, subsystem: "FS", message: "Imported \(url.lastPathComponent) (\(size) bytes).")
        return ImportedFile(
            id: UUID(),
            displayName: url.lastPathComponent,
            sizeBytes: size,
            storedURL: stored,
            importedAt: Date()
        )
    }

    func listLibrary() -> [URL] {
        guard let library = try? self.libraryDirectory() else { return [] }
        let items = (try? self.manager.contentsOfDirectory(
            at: library,
            includingPropertiesForKeys: nil
        )) ?? []
        return items.filter { $0.pathExtension.lowercased() == "bin" }.sorted { lhs, rhs in
            lhs.lastPathComponent < rhs.lastPathComponent
        }
    }

    func deleteLibraryFile(at url: URL) throws {
        try self.manager.removeItem(at: url)
    }

    func loadProgram(at url: URL) throws -> Data {
        let data = try Data(contentsOf: url)
        guard !data.isEmpty, data.count <= Self.maxImportBytes else {
            throw SandboxFSError.tooLarge(maxBytes: Self.maxImportBytes)
        }
        return data
    }

    private func storeBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(options: [.minimalBookmark], includingResourceValuesForKeys: nil, relativeTo: nil)
            self.lock.lock()
            var saved = UserDefaults.standard.array(forKey: self.bookmarkKey) as? [Data] ?? []
            saved.append(data)
            UserDefaults.standard.set(saved, forKey: self.bookmarkKey)
            self.lock.unlock()
        } catch {
            Logger.shared.log(.warning, subsystem: "FS", message: "Bookmark failed: \(error).")
        }
    }
}
