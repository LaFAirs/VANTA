import SwiftUI

public enum Appearance: String, CaseIterable {
    case system, dark, light
    var colorScheme: ColorScheme? {
        switch self { case .system: return nil; case .dark: return .dark; case .light: return .light }
    }
}

/// Settings, grouped per spec (General / Signing / Repositories / Installation / Advanced).
@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    // General
    @AppStorage("appearance") var appearanceRaw = Appearance.dark.rawValue
    @AppStorage("largerText") var largerText = false
    @AppStorage("reduceMotion") var reduceMotion = false
    @AppStorage("notifications") var notifications = true

    // Signing
    @AppStorage("defaultSigner") var defaultSignerID = "local"
    @AppStorage("autoVerify") var autoVerify = true

    // Repositories
    @AppStorage("repoUpdateIntervalH") var repoUpdateIntervalH = 24
    @AppStorage("allowInsecureRepos") var allowInsecureRepos = false

    // Installation
    @AppStorage("confirmBeforeInstall") var confirmBeforeInstall = true
    @AppStorage("installNotifications") var installNotifications = true

    // Advanced
    @AppStorage("debugLogs") var debugLogs = false

    var appearance: Appearance {
        get { Appearance(rawValue: appearanceRaw) ?? .dark }
        set { appearanceRaw = newValue.rawValue }
    }

    func reset() {
        for k in ["appearance", "largerText", "reduceMotion", "notifications",
                  "defaultSigner", "autoVerify", "repoUpdateIntervalH",
                  "allowInsecureRepos", "confirmBeforeInstall",
                  "installNotifications", "debugLogs"] {
            UserDefaults.standard.removeObject(forKey: k)
        }
        objectWillChange.send()
    }
}
