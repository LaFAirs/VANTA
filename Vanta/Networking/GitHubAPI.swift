import Foundation

/// GitHub public profile loader with disk caching. Falls back to placeholder offline.
public actor GitHubAPI {
    /// Public GitHub user record (snake_case mapped automatically).
    public struct User: Codable, Sendable {
        /// Login name.
        public var login: String
        /// Avatar URL, if provided.
        public var avatarURL: URL?
        /// Profile URL, if provided.
        public var htmlURL: URL?
        /// Display name, if provided.
        public var name: String?
    }

    /// Shared instance.
    public static let shared = GitHubAPI()
    private var cachedAvatar: Data?
    private var lastFetch: Date?

    /// Loads the public profile. Returns nil offline (caller shows fallback).
    public func loadUser(username: String) async -> User? {
        guard let url = URL(string: "https://api.github.com/users/\(username)") else { return nil }
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: 15)
        request.setValue("VANTA-iOS", forHTTPHeaderField: "User-Agent")
        do {
            let session = URLSession(configuration: .default)
            let (data, response) = try await session.data(for: request)
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                self.lastFetch = Date()
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try? decoder.decode(User.self, from: data)
            }
        } catch { /* offline → nil, caller shows fallback */ }
        return nil
    }

    /// Loads avatar bytes with a 24h in-memory cache.
    public func loadAvatarData(from url: URL?) async -> Data? {
        guard let url else { return self.cachedAvatar }
        if let cachedAvatar, let lastFetch, Date().timeIntervalSince(lastFetch) < 24 * 3600 {
            return cachedAvatar
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            self.cachedAvatar = data
            return data
        } catch { return self.cachedAvatar }
    }
}
