import Foundation

/// GitHub public profile loader with disk caching. Falls back to placeholder offline.
public actor GitHubAPI {
    public struct User: Codable, Sendable {
        public var login: String
        public var avatar_url: URL?
        public var html_url: URL?
        public var name: String?
    }

    public static let shared = GitHubAPI()
    private let cache = URLCache(memoryCapacity: 4_000_000, diskCapacity: 20_000_000)
    private var cachedAvatar: Data?
    private var lastFetch: Date?

    public func loadUser(username: String) async -> User? {
        guard let url = URL(string: "https://api.github.com/users/\(username)") else { return nil }
        var req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad,
                             timeoutInterval: 15)
        req.setValue("VANTA-iOS", forHTTPHeaderField: "User-Agent")
        do {
            let session = URLSession(configuration: .default)
            let (data, resp) = try await session.data(for: req)
            if (resp as? HTTPURLResponse)?.statusCode == 200 {
                lastFetch = Date()
                return try? JSONDecoder().decode(User.self, from: data)
            }
        } catch { /* offline → nil, caller shows fallback */ }
        return nil
    }

    public func loadAvatarData(from url: URL?) async -> Data? {
        guard let url else { return cachedAvatar }
        if let cachedAvatar, let lastFetch, Date().timeIntervalSince(lastFetch) < 24 * 3600 {
            return cachedAvatar
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            cachedAvatar = data
            return data
        } catch { return cachedAvatar }
    }
}
