import Foundation

/// Severity of a log entry, from verbose diagnostics to fatal errors.
enum LogLevel: String, Sendable, CaseIterable, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

/// One structured log entry with timestamp, level, subsystem and message.
struct LogEntry: Sendable, Identifiable, Codable {
    let id: UUID
    let date: Date
    let level: LogLevel
    let subsystem: String
    let message: String

    init(level: LogLevel, subsystem: String, message: String) {
        self.id = UUID()
        self.date = Date()
        self.level = level
        self.subsystem = subsystem
        self.message = message
    }
}

/// Thread-safe in-memory log store. Entries can be listed, filtered and
/// exported to a text file. No networking, no telemetry.
final class Logger: @unchecked Sendable {
    static let shared = Logger()

    private let lock = NSLock()
    private var entries: [LogEntry] = []
    private let maxEntries = 2000

    private init() {}

    func log(_ level: LogLevel, subsystem: String, message: String) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.entries.append(LogEntry(level: level, subsystem: subsystem, message: message))
        if self.entries.count > self.maxEntries {
            self.entries.removeFirst(self.entries.count - self.maxEntries)
        }
    }

    func snapshot(minimumLevel: LogLevel? = nil) -> [LogEntry] {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let minimum = minimumLevel else { return self.entries }
        let order: [LogLevel] = [.debug, .info, .warning, .error]
        guard let threshold = order.firstIndex(of: minimum) else { return self.entries }
        return self.entries.filter { entry in
            guard let index = order.firstIndex(of: entry.level) else { return false }
            return index >= threshold
        }
    }

    func clear() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.entries.removeAll()
    }

    /// Writes all entries to a UTF-8 text file and returns its URL.
    func export() throws -> URL {
        let lines = self.snapshot().map { entry in
            "\(Self.formatter.string(from: entry.date)) [\(entry.level.rawValue)] \(entry.subsystem): \(entry.message)"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("switchemu-log.txt")
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
