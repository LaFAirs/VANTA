import SwiftUI

@main
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
