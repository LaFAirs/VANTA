import SwiftUI

/// Adaptive root: TabView on iPhone, NavigationSplitView sidebar on iPad.
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var sidebarSelection: AppState.Tab? = .home

    var body: some View {
        if sizeClass == .regular {
            iPadSidebar
        } else {
            iPhoneTabs
        }
    }

    // MARK: - iPhone

    private var iPhoneTabs: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView().tabItem { Label("Home", systemImage: "house.fill") }.tag(AppState.Tab.home)
            AppsView().tabItem { Label("Apps", systemImage: "square.stack.3d.up.fill") }.tag(AppState.Tab.apps)
            DiscoverView().tabItem { Label("Discover", systemImage: "compass.fill") }.tag(AppState.Tab.discover)
            FilesView().tabItem { Label("Files", systemImage: "folder.fill") }.tag(AppState.Tab.files)
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(AppState.Tab.settings)
        }
        .tint(VantaDS.accent)
    }

    // MARK: - iPad

    private var iPadSidebar: some View {
        NavigationSplitView {
            List(selection: $sidebarSelection) {
                Section("VANTA") {
                    Label("Home", systemImage: "house.fill").tag(AppState.Tab.home)
                    Label("Apps", systemImage: "square.stack.3d.up.fill").tag(AppState.Tab.apps)
                    Label("Discover", systemImage: "compass.fill").tag(AppState.Tab.discover)
                }
                Section("Manage") {
                    Label("Certificates", systemImage: "key.fill").tag(AppState.Tab.files)
                    Label("Files", systemImage: "folder.fill").tag(AppState.Tab.files)
                    Label("Settings", systemImage: "gearshape.fill").tag(AppState.Tab.settings)
                }
            }
            .navigationTitle("VANTA")
        } detail: {
            switch sidebarSelection ?? .home {
            case .home: HomeView()
            case .apps: AppsView()
            case .discover: DiscoverView()
            case .files: FilesView()
            case .settings: SettingsView()
            }
        }
        .tint(VantaDS.accent)
    }
}
