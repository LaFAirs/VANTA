import SwiftUI

/// App discovery across user-added repositories.
struct DiscoverView: View {
    @State private var items: [(repo: AppRepository, app: RepoApp)] = []
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if self.items.isEmpty {
                        ComingSoon("Add a repository to discover apps. Repositories → + Add Repository.")
                    }
                    ForEach(self.filtered, id: \.app.id) { entry in
                        VantaCard {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(VantaDS.secondary)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(String(entry.app.name.prefix(1))).bold()
                                            .foregroundStyle(VantaDS.accent)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.app.name).font(.headline).lineLimit(1)
                                    Text(entry.app.developer)
                                        .font(.caption)
                                        .foregroundStyle(VantaDS.secondaryText)
                                    Text("v\(entry.app.version)")
                                        .font(.caption2)
                                        .foregroundStyle(VantaDS.secondaryText)
                                    Text("Source: \(entry.repo.name)")
                                        .font(.caption2)
                                        .foregroundStyle(VantaDS.accent)
                                }
                                Spacer()
                                Button("Get") { Task { await self.get(entry.app) } }
                                    .buttonStyle(.borderedProminent).tint(VantaDS.accent)
                                    .accessibilityLabel("Install \(entry.app.name) from \(entry.repo.name)")
                            }
                            if !entry.app.localizedDescription.isEmpty {
                                Text(entry.app.localizedDescription).font(.subheadline)
                                    .foregroundStyle(VantaDS.secondaryText).lineLimit(3)
                            }
                        }
                    }
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Discover")
            .searchable(text: self.$query, prompt: "Search apps")
            .task { self.items = await RepositoryStore.shared.allApps() }
        }
    }

    private var filtered: [(repo: AppRepository, app: RepoApp)] {
        guard !self.query.isEmpty else { return self.items }
        return self.items.filter { $0.app.name.localizedCaseInsensitiveContains(self.query) }
    }

    private func get(_ app: RepoApp) async {
        do {
            _ = try await IPAImporter.shared.enqueueURL(app.downloadURL, allowInsecure: false)
            await Logger.shared.log(.success, "Queued \(app.name) v\(app.version)")
        } catch let caught as VantaError {
            await Logger.shared.log(.error, caught.reason)
        } catch {
            await Logger.shared.log(.error, error.localizedDescription)
        }
    }
}

/// User-added repository management with validation.
struct RepositoriesView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var repos: [AppRepository] = []
    @State private var urlText = ""
    @State private var error: VantaError?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let currentError = error { VantaErrorCard(currentError) }
                    ForEach(self.repos, id: \.id) { repo in
                        RepositoryRow(repo: repo, onDelete: {
                            Task { await self.deleteRepo(repo) }
                        })
                    }
                    self.addCard
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Repositories")
            .task { await self.load() }
        }
    }

    private var addCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Repository").font(.headline)
                TextField("https://example.com/repo.json", text: self.$urlText)
                    .textFieldStyle(.roundedBorder).textInputAutocapitalization(.never)
                VantaPrimaryButton(self.busy ? "Validating…" : "Add & Validate") {
                    Task { await self.add() }
                }
            }
        }
    }

    private func load() async {
        self.repos = await RepositoryStore.shared.all()
    }

    private func deleteRepo(_ repo: AppRepository) async {
        await RepositoryStore.shared.remove(id: repo.id)
        await self.load()
    }

    private func add() async {
        do {
            self.busy = true
            self.error = nil
            let url = try Validators.parseURL(self.urlText)
            let repo = try await RepositoryClient.shared.fetch(
                url: url,
                allowInsecure: self.settings.allowInsecureRepos
            )
            await RepositoryStore.shared.add(repo)
            await Logger.shared.log(.success, "Added repository \(repo.name) (\(repo.apps.count) apps)")
            self.urlText = ""
            await self.load()
        } catch let caught as VantaError {
            self.error = caught
        } catch {
            self.error = .repositoryInvalid(reason: error.localizedDescription)
        }
        self.busy = false
    }
}

/// Single repository row with remove action.
private struct RepositoryRow: View {
    /// The repository to display.
    let repo: AppRepository
    /// Remove handler.
    var onDelete: () -> Void

    /// Row body.
    var body: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(self.repo.name).font(.headline)
                    Spacer()
                    Button(role: .destructive, action: self.onDelete, label: {
                        Image(systemName: "trash").foregroundStyle(VantaDS.danger)
                    })
                    .accessibilityLabel("Remove \(self.repo.name)")
                }
                Text(self.repo.url.absoluteString).font(.caption).foregroundStyle(VantaDS.secondaryText)
                Text("\(self.repo.apps.count) apps").font(.caption2).foregroundStyle(VantaDS.secondaryText)
            }
        }
    }
}
