import OSLog

/// Unified-logging backend. Lives in its own file so `OSLog.Logger` never
/// collides with the app's `Logger` actor.
enum VantaOSLog {
    /// App subsystem logger.
    static let vanta = Logger(subsystem: "com.vanta.app", category: "vanta")
}
