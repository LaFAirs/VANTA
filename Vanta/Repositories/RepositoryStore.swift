import Foundation

/// Fetches and caches repository manifests (URLSession + URLCache, lazy).
public actor RepositoryClient {
    /// Shared instance.
    public static let shared = RepositoryClient()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 8_000_000, diskCapacity: 50_000_000)
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    /// Fetches and validates a manifest.
    public func fetch(url: URL, allowInsecure: Bool) async throws -> AppRepository {
        try Validators.requireSecure(url, acknowledgedInsecure: allowInsecure)
        let (data, response) = try await self.session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw VantaError.repositoryInvalid(reason: "Repository returned HTTP \(status).")
        }
        return try RepositoryValidator.validate(data: data, sourceURL: url, allowInsecure: allowInsecure)
    }
}

/// Registry of user-added repositories.
public actor RepositoryStore {
    /// Shared instance.
    public static let shared = RepositoryStore()
    private var repos: [AppRepository] = []

    /// All repositories.
    public func all() -> [AppRepository] { self.repos }

    /// Every app tagged with its repository.
    public func allApps() -> [(repo: AppRepository, app: RepoApp)] {
        self.repos.flatMap { repo in repo.apps.map { (repo: repo, app: $0) } }
    }

    /// Adds or replaces a repository by identifier.
    public func add(_ repo: AppRepository) {
        if let index = self.repos.firstIndex(where: { $0.identifier == repo.identifier }) {
            self.repos[index] = repo
        } else {
            self.repos.append(repo)
        }
    }

    /// Removes a repository.
    public func remove(id: UUID) {
        self.repos.removeAll { $0.id == id }
    }
}
