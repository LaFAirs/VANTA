import SwiftUI

struct DiscoverView: View {
    @State private var items: [(repo: AppRepository, app: RepoApp)] = []
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if items.isEmpty {
                        ComingSoon("Add a repository to discover apps. Repositories → + Add Repository.")
                    }
                    ForEach(filtered, id: \.app.id) { entry in
                        VantaCard {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(VantaDS.secondary)
                                    .frame(width: 48, height: 48)
                                    .overlay(Text(String(entry.app.name.prefix(1))).bold().foregroundStyle(VantaDS.accent))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.app.name).font(.headline).lineLimit(1)
                                    Text(entry.app.developer).font(.caption).foregroundStyle(VantaDS.secondaryText)
                                    Text("v\(entry.app.version)").font(.caption2).foregroundStyle(VantaDS.secondaryText)
                                    Text("Source: \(entry.repo.name)").font(.caption2).foregroundStyle(VantaDS.accent)
                                }
                                Spacer()
                                Button("Get") { Task { await get(entry.app) } }
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
            .searchable(text: $query, prompt: "Search apps")
            .task { items = await RepositoryStore.shared.allApps() }
        }
    }

    private var filtered: [(repo: AppRepository, app: RepoApp)] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.app.name.localizedCaseInsensitiveContains(query) }
    }

    private func get(_ app: RepoApp) async {
        do {
            _ = try await IPAImporter.shared.enqueueURL(app.downloadURL, allowInsecure: false)
            await Logger.shared.log(.success, "Queued \(app.name) v\(app.version)")
        } catch let e as VantaError {
            await Logger.shared.log(.error, e.reason)
        } catch {
            await Logger.shared.log(.error, error.localizedDescription)
        }
    }
}

struct RepositoriesView: View {
    @EnvironmentObject private var appState: AppState
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
                    ForEach(repos, id: \.id) { repo in
                        RepositoryRow(repo: repo, onDelete: {
                            Task { await deleteRepo(repo) }
                        })
                    }
                    addCard
                }.padding()
            }
            .background(VantaDS.background.ignoresSafeArea())
            .navigationTitle("Repositories")
            .task { await load() }
        }
    }

    private var addCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Repository").font(.headline)
                TextField("https://example.com/repo.json", text: $urlText)
                    .textFieldStyle(.roundedBorder).textInputAutocapitalization(.never)
                VantaPrimaryButton(busy ? "Validating…" : "Add & Validate") { Task { await add() } }
            }
        }
    }

    private func load() async { repos = await RepositoryStore.shared.all() }

    private func deleteRepo(_ repo: AppRepository) async {
        await RepositoryStore.shared.remove(id: repo.id)
        await load()
    }

    private func add() async {
        do {
            busy = true; error = nil
            let url = try Validators.parseURL(urlText)
            let repo = try await RepositoryClient.shared.fetch(url: url, allowInsecure: settings.allowInsecureRepos)
            await RepositoryStore.shared.add(repo)
            await Logger.shared.log(.success, "Added repository \(repo.name) (\(repo.apps.count) apps)")
            urlText = ""
            await load()
        } catch let e as VantaError { self.error = e }
        catch { self.error = .repositoryInvalid(reason: error.localizedDescription) }
        busy = false
    }
}

private struct RepositoryRow: View {
    let repo: AppRepository
    var onDelete: () -> Void

    var body: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(repo.name).font(.headline)
                    Spacer()
                    Button(role: .destructive, action: onDelete, label: {
                        Image(systemName: "trash").foregroundStyle(VantaDS.danger)
                    })
                    .accessibilityLabel("Remove \(repo.name)")
                }
                Text(repo.url.absoluteString).font(.caption).foregroundStyle(VantaDS.secondaryText)
                Text("\(repo.apps.count) apps").font(.caption2).foregroundStyle(VantaDS.secondaryText)
            }
        }
    }
}
