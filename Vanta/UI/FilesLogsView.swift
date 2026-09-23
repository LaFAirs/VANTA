import SwiftUI

struct FilesView: View {
    @State private var area: VantaFileStore.Area = .ipas
    @State private var items: [VantaFileStore.Item] = []
    @State private var error: VantaError?

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Area", selection: $area) {
                    ForEach(VantaFileStore.Area.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).padding(.horizontal)
                List {
                    ForEach(items) { i in
                        HStack {
                            Image(systemName: icon(for: i.url)).foregroundStyle(VantaDS.accent)
                            VStack(alignment: .leading) {
                                Text(i.url.lastPathComponent).lineLimit(1)
                                Text(ByteCountFormatter.string(fromByteCount: i.size, countStyle: .file))
                                    .font(.caption).foregroundStyle(VantaDS.secondaryText)
                            }
                            Spacer()
                            ShareLink(item: i.url) { Image(systemName: "square.and.arrow.up") }
                        }
                        .swipeActions {
                            Button(role: .destructive) { Task { await delete(i) } } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(VantaDS.background)
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Files")
            .task(id: area) { await load() }
        }
    }

    private func load() async {
        do { items = try await VantaFileStore.shared.list(area) }
        catch { error = .ipaNotFound }
    }
    private func delete(_ i: VantaFileStore.Item) async {
        try? await VantaFileStore.shared.delete(i.url)
        await load()
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

struct LogsView: View {
    @EnvironmentObject private var center: LogCenter
    @State private var filter: LogLevel? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(shown) { e in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(color(e.level)).frame(width: 8, height: 8).padding(.top, 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.message).font(.subheadline)
                            Text("\(e.date.formatted(date: .omitted, time: .standard)) · \(e.level.rawValue.uppercased())")
                                .font(.caption2).foregroundStyle(VantaDS.secondaryText)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(VantaDS.background)
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: center.exportText) { Image(systemName: "square.and.arrow.up") }
                    Button("Clear", role: .destructive) { center.clear() }
                }
            }
        }
    }

    private var shown: [LogEntry] {
        guard let filter else { return center.entries.reversed() }
        return center.entries.filter { $0.level == filter }.reversed()
    }
    private func color(_ l: LogLevel) -> Color {
        switch l {
        case .info: return VantaDS.accent
        case .success: return VantaDS.success
        case .warning: return VantaDS.warning
        case .error: return VantaDS.danger
        case .debug: return VantaDS.secondaryText
        }
    }
}
