import Foundation

/// Fetches + caches repository manifests (URLSession + URLCache, lazy).
public actor RepositoryClient {
    public static let shared = RepositoryClient()
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.urlCache = URLCache(memoryCapacity: 8_000_000, diskCapacity: 50_000_000)
        c.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: c)
    }()

    public func fetch(url: URL, allowInsecure: Bool) async throws -> AppRepository {
        try Validators.requireSecure(url, acknowledgedInsecure: allowInsecure)
        let (data, resp) = try await session.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw VantaError.repositoryInvalid(reason: "Repository returned HTTP \((resp as? HTTPURLResponse)?.statusCode ?? -1).")
        }
        return try RepositoryValidator.validate(data: data, sourceURL: url, allowInsecure: allowInsecure)
    }
}

/// Registry of user-added repositories.
public actor RepositoryStore {
    public static let shared = RepositoryStore()
    private var repos: [AppRepository] = []

    public func all() -> [AppRepository] { repos }
    public func allApps() -> [(repo: AppRepository, app: RepoApp)] {
        repos.flatMap { r in r.apps.map { (r, $0) } }
    }
    public func add(_ r: AppRepository) {
        if let i = repos.firstIndex(where: { $0.identifier == r.identifier }) { repos[i] = r }
        else { repos.append(r) }
    }
    public func remove(id: UUID) { repos.removeAll { $0.id == id } }
}
