import SwiftUI

/// On-device file browser across VANTA storage areas.
struct FilesView: View {
    @State private var area: VantaFileStore.Area = .ipas
    @State private var items: [VantaFileStore.Item] = []
    @State private var error: VantaError?

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Area", selection: self.$area) {
                    ForEach(VantaFileStore.Area.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }.pickerStyle(.segmented).padding(.horizontal)
                List {
                    ForEach(self.items) { item in
                        HStack {
                            Image(systemName: self.icon(for: item.url)).foregroundStyle(VantaDS.accent)
                            VStack(alignment: .leading) {
                                Text(item.url.lastPathComponent).lineLimit(1)
                                Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                    .font(.caption).foregroundStyle(VantaDS.secondaryText)
                            }
                            Spacer()
                            ShareLink(item: item.url) { Image(systemName: "square.and.arrow.up") }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await self.delete(item) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(VantaDS.background)
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Files")
            .task(id: self.area) { await self.load() }
        }
    }

    private func load() async {
        do {
            self.items = try await VantaFileStore.shared.list(self.area)
        } catch {
            self.error = .ipaNotFound
        }
    }

    private func delete(_ item: VantaFileStore.Item) async {
        try? await VantaFileStore.shared.delete(item.url)
        await self.load()
    }

    private func icon(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "ipa": return "app.fill"
        case "p12", "pfx": return "key.fill"
        case "mobileprovision": return "doc.badge.gearshape.fill"
        case "log", "txt": return "doc.text.fill"
        default: return "doc.fill"
        }
    }
}

/// Categorized log viewer with export.
struct LogsView: View {
    @EnvironmentObject private var center: LogCenter
    @State private var filter: LogLevel?

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.shown) { entry in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(self.color(entry.level)).frame(width: 8, height: 8).padding(.top, 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.message).font(.subheadline)
                            Text(self.subtitle(for: entry))
                                .font(.caption2)
                                .foregroundStyle(VantaDS.secondaryText)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(VantaDS.background)
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: self.center.exportText) { Image(systemName: "square.and.arrow.up") }
                    Button("Clear", role: .destructive) { self.center.clear() }
                }
            }
        }
    }

    private var shown: [LogEntry] {
        guard let filter else { return self.center.entries.reversed() }
        return self.center.entries.filter { $0.level == filter }.reversed()
    }

    private func subtitle(for entry: LogEntry) -> String {
        let timestamp = entry.date.formatted(date: .omitted, time: .standard)
        let level = entry.level.rawValue.uppercased()
        return "\(timestamp) · \(level)"
    }

    private func color(_ level: LogLevel) -> Color {
        switch level {
        case .info: return VantaDS.accent
        case .success: return VantaDS.success
        case .warning: return VantaDS.warning
        case .error: return VantaDS.danger
        case .debug: return VantaDS.secondaryText
        }
    }
}
