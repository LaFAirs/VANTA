import SwiftUI

/// In-app log viewer with level filter, clear and shareable export.
struct LogsView: View {
    @State private var entries: [LogEntry] = []
    @State private var selectedLevel = "All"
    @State private var shareURL: URL?

    private let levels = ["All", "DEBUG", "INFO", "WARNING", "ERROR"]

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Level", selection: self.$selectedLevel) {
                    ForEach(self.levels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                List(self.filtered()) { entry in
                    VStack(alignment: .leading) {
                        Text("[\(entry.level.rawValue)] \(entry.subsystem)")
                            .font(.caption)
                            .foregroundStyle(self.color(for: entry.level))
                        Text(entry.message)
                            .font(.body)
                    }
                }
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        self.export()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        Logger.shared.clear()
                        self.reload()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
            .sheet(isPresented: self.shareBinding()) {
                if let url = self.shareURL {
                    ShareSheet(url: url)
                }
            }
            .onAppear {
                self.reload()
            }
        }
    }

    private func filtered() -> [LogEntry] {
        guard self.selectedLevel != "All" else { return self.entries }
        return self.entries.filter { $0.level.rawValue == self.selectedLevel }
    }

    private func reload() {
        self.entries = Logger.shared.snapshot()
    }

    private func shareBinding() -> Binding<Bool> {
        Binding(
            get: { self.shareURL != nil },
            set: { newValue in if !newValue { self.shareURL = nil } }
        )
    }

    private func export() {
        do {
            self.shareURL = try Logger.shared.export()
        } catch {
            Logger.shared.log(.error, subsystem: "UI", message: "Export failed: \(error).")
            self.reload()
        }
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

/// UIKit share sheet wrapper for the exported log file.
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [self.url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
