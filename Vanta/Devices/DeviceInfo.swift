import UIKit

/// Device facts via public APIs only. No private calls, no fake identifiers.
public enum DeviceInfo {
    /// Device model (e.g. iPhone).
    public static var modelName: String { UIDevice.current.model }
    /// OS name (e.g. iOS).
    public static var systemName: String { UIDevice.current.systemName }
    /// OS version.
    public static var systemVersion: String { UIDevice.current.systemVersion }
    /// True on iPad.
    public static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    /// One-line device summary.
    public static var summary: String { "\(modelName) · \(systemName) \(systemVersion)" }
}
