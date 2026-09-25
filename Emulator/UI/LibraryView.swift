import SwiftUI
import UniformTypeIdentifiers

/// Game library: lists imported `.bin` demo files, imports new ones via the
/// system document picker and starts the selected file. Unsupported files
/// are rejected with a message; the app never crashes on bad input.
struct LibraryView: View {
    @EnvironmentObject private var state: EmulatorAppState
    @State private var showingImporter = false
    @State private var notice: String?

    var body: some View {
        NavigationStack {
            List {
                if self.state.libraryFiles.isEmpty {
                    Text("No demo files yet. Import a .bin file you created yourself.")
                        .foregroundStyle(.secondary)
                }
                ForEach(self.state.libraryFiles, id: \.self) { url in
                    Button {
                        self.start(url: url)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(url.lastPathComponent).font(.headline)
                            Text(url.path).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    self.delete(at: offsets)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                Button {
                    self.showingImporter = true
                } label: {
                    Label("Add game", systemImage: "plus")
                }
            }
            .fileImporter(
                isPresented: self.$showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "bin") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                self.handleImport(result: result)
            }
            .alert("Notice", isPresented: self.bindingForNotice()) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.notice ?? "")
            }
            .onAppear {
                self.state.refreshLibrary()
            }
        }
    }

    private func start(url: URL) {
        do {
            let program = try self.state.filesystem.loadProgram(at: url)
            if self.state.core.start(with: program) {
                self.state.selectedFile = url
                self.state.refreshStatus()
            } else {
                self.notice = self.state.core.currentFailure() ?? "Could not start."
            }
        } catch {
            self.notice = "Could not load file: \(error)."
            Logger.shared.log(.error, subsystem: "UI", message: "Load failed: \(error).")
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let url = self.state.libraryFiles[index]
            do {
                try self.state.filesystem.deleteLibraryFile(at: url)
            } catch {
                self.notice = "Delete failed: \(error)."
            }
        }
        self.state.refreshLibrary()
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                _ = try self.state.filesystem.importFile(from: url)
                self.state.refreshLibrary()
            } catch {
                self.notice = self.friendlyImportError(error)
            }
        case .failure(let error):
            self.notice = "Import cancelled or failed: \(error.localizedDescription)."
        }
    }

    private func friendlyImportError(_ error: Error) -> String {
        guard let fileError = error as? SandboxFSError else {
            return "Import failed: \(error)."
        }
        switch fileError {
        case .tooLarge(let max):
            return "File too large (max \(max / 1024 / 1024) MiB of own .bin data)."
        case .unsupportedType:
            return "Unsupported type. Only own .bin demo files; no commercial formats."
        case .accessDenied:
            return "No access to that file."
        case .copyFailed:
            return "Copy into sandbox failed."
        case .bookmarkFailed:
            return "Could not persist access."
        }
    }

    private func bindingForNotice() -> Binding<Bool> {
        Binding(
            get: { self.notice != nil },
            set: { newValue in if !newValue { self.notice = nil } }
        )
    }
}
