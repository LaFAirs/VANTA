import SwiftUI

/// Adaptive root: tab bar on compact width, sidebar on regular width.
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var sidebarSelection: AppState.Tab? = .home
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        ViewThatFits {
            iPadSidebar
            iPhoneTabs
        }
    }

    // MARK: - iPhone

    private var iPhoneTabs: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppState.Tab.home)
                .accessibilityLabel("Home tab")
            AppsView()
                .tabItem { Label("Apps", systemImage: "square.stack.3d.up.fill") }
                .tag(AppState.Tab.apps)
                .accessibilityLabel("Apps tab")
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "compass.fill") }
                .tag(AppState.Tab.discover)
                .accessibilityLabel("Discover tab")
            CertificatesView()
                .tabItem { Label("Certificates", systemImage: "key.fill") }
                .tag(AppState.Tab.certificates)
                .accessibilityLabel("Certificates tab")
            FilesView()
                .tabItem { Label("Files", systemImage: "folder.fill") }
                .tag(AppState.Tab.files)
                .accessibilityLabel("Files tab")
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppState.Tab.settings)
                .accessibilityLabel("Settings tab")
        }
        .tint(VantaDS.accent)
    }

    // MARK: - iPad

    private var iPadSidebar: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $sidebarSelection) {
                Section("VANTA") {
                    Label("Home", systemImage: "house.fill").tag(AppState.Tab.home)
                    Label("Apps", systemImage: "square.stack.3d.up.fill").tag(AppState.Tab.apps)
                    Label("Discover", systemImage: "compass.fill").tag(AppState.Tab.discover)
                }
                Section("Manage") {
                    Label("Certificates", systemImage: "key.fill").tag(AppState.Tab.certificates)
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
            case .certificates: CertificatesView()
            case .files: FilesView()
            case .settings: SettingsView()
            }
        }
        .tint(VantaDS.accent)
    }
}
