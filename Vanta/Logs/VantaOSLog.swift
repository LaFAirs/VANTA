import Foundation
import os

/// Unified-logging backend. Uses `os_log` directly so there is no name
/// clash with the app's `Logger` actor.
enum VantaOSLog {
    /// Mirrors one entry to the unified log.
    static func record(level: LogLevel, message: String) {
        switch level {
        case .debug:
            os_log("%{public}@", log: .default, type: .debug, message)
        case .info:
            os_log("%{public}@", log: .default, type: .info, message)
        case .success:
            os_log("%{public}@", log: .default, type: .default, message)
        case .warning:
            os_log("%{public}@", log: .default, type: .error, message)
        case .error:
            os_log("%{public}@", log: .default, type: .fault, message)
        }
    }
}
