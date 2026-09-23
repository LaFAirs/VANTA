import SwiftUI

/// Application entry point. Main-actor isolated so shared
/// MainActor stores can be injected directly.
@main
@MainActor
struct VantaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var logger = LogCenter.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(settings)
                .environmentObject(logger)
                .preferredColorScheme(settings.appearance.colorScheme)
                .dynamicTypeSize(settings.largerText ? .accessibility2 : .large)
        }
    }
}
