import SwiftUI

/// Global app state: selected tab, import sheet, activity. Kept tiny on purpose.
@MainActor
final class AppState: ObservableObject {
    /// Top-level destinations (iPhone tabs and iPad sidebar share them).
    enum Tab: Hashable {
        /// Home dashboard.
        case home
        /// Managed apps.
        case apps
        /// Repository discovery.
        case discover
        /// Signing certificates.
        case certificates
        /// On-device files.
        case files
        /// Settings.
        case settings
    }

    @Published var selectedTab: Tab = .home
    @Published var showingIPAImport = false
    @Published var showingAddRepository = false
    @Published var activePipelineID: UUID?
}
