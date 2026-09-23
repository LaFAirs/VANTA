import UIKit

/// Device facts via public APIs only. No private calls, no fake identifiers.
public enum DeviceInfo {
    public static var modelName: String { UIDevice.current.model }
    public static var systemName: String { UIDevice.current.systemName }
    public static var systemVersion: String { UIDevice.current.systemVersion }
    public static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    public static var summary: String { "\(modelName) · \(systemName) \(systemVersion)" }
}
