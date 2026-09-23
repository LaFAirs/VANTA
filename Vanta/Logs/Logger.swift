import Foundation
import SwiftUI

public enum LogLevel: String, Codable, CaseIterable, Sendable {
    case info, success, warning, error, debug
}

public struct LogEntry: Identifiable, Codable, Sendable {
    public var id: UUID
    public var date: Date
    public var level: LogLevel
    public var message: String
    public init(id: UUID = UUID(), date: Date = Date(), level: LogLevel, message: String) {
        self.id = id; self.date = date; self.level = level; self.message = message
    }
}

/// Central logger: actor-backed, main-thread published mirror for SwiftUI.
public actor Logger {
    public static let shared = Logger()
    private var entries: [LogEntry] = []
    private var listeners: [@Sendable ([LogEntry]) -> Void] = []

    public func log(_ level: LogLevel, _ message: String) {
        entries.append(LogEntry(level: level, message: message))
        if entries.count > 2000 { entries.removeFirst(entries.count - 2000) }
        let snapshot = entries
        for l in listeners { l(snapshot) }
    }

    public func snapshot() -> [LogEntry] { entries }
    public func clear() { entries.removeAll() }

    public func onUpdate(_ fn: @escaping @Sendable ([LogEntry]) -> Void) {
        listeners.append(fn)
    }

    public func export() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"
        return entries.map { "[\(f.string(from: $0.date))] [\($0.level.rawValue.uppercased())] \($0.message)" }
            .joined(separator: "\n")
    }
}

/// Observable mirror so views update without awaiting the actor directly.
@MainActor
final class LogCenter: ObservableObject {
    static let shared = LogCenter()
    @Published private(set) var entries: [LogEntry] = []
    private init() {
        Task {
            await Logger.shared.onUpdate { [weak self] snap in
                Task { @MainActor in self?.entries = snap }
            }
            let snap = await Logger.shared.snapshot()
            self.entries = snap
        }
    }
    func log(_ level: LogLevel, _ msg: String) {
        Task { await Logger.shared.log(level, msg) }
    }
    func clear() { Task { await Logger.shared.clear(); entries = [] } }
    var exportText: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"
        return entries.map { "[\(f.string(from: $0.date))] [\($0.level.rawValue.uppercased())] \($0.message)" }.joined(separator: "\n")
    }
}
