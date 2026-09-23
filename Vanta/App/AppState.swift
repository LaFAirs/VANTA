import SwiftUI

/// Global app state: selected tab, import sheet, activity. Kept tiny on purpose.
@MainActor
final class AppState: ObservableObject {
    enum Tab: Hashable { case home, apps, discover, files, settings }

    @Published var selectedTab: Tab = .home
    @Published var showingIPAImport = false
    @Published var showingAddRepository = false
    @Published var activePipelineID: UUID?
}
