import SwiftUI

/// SwitchEmu application entry point. Tab navigation adapts to iPhone and
/// iPad; orientation support is declared in Info.plist.
@main
struct SwitchEmuApp: App {
    @StateObject private var state = EmulatorAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.state)
        }
    }
}

/// Root navigation: library, emulation, settings and logs.
struct ContentView: View {
    @EnvironmentObject private var state: EmulatorAppState

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "gamecontroller") }
            EmulatorView()
                .tabItem { Label("Emulate", systemImage: "play.circle") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
            LogsView()
                .tabItem { Label("Logs", systemImage: "doc.text") }
        }
        .environmentObject(self.state)
    }
}
