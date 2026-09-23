import Foundation

/// Central, honest configuration. No hardcoded secrets.
/// Maintainer: set your GitHub identity here; the app reads it at runtime.
public enum DeveloperConfig {
    public static let appName = "VANTA"
    public static let tagline = "Advanced iOS & iPadOS Sideloading."
    public static let appVersion = "1.0.0"
    public static let buildNumber = "100"

    // GitHub identity for About page, links, and avatar loading.
    public static let githubUsername = "dbudakli1402-collab"
    public static var githubProfileURL: URL? {
        URL(string: "https://github.com/\(githubUsername)")
    }
    public static var githubRepositoryURL: URL? {
        URL(string: "https://github.com/\(githubUsername)/VANTA")
    }
    public static var githubAPIUserURL: URL? {
        URL(string: "https://api.github.com/users/\(githubUsername)")
    }
    public static var documentationURL: URL? {
        githubRepositoryURL?.appendingPathComponent("tree/main/Documentation")
    }
    public static var issuesURL: URL? {
        githubRepositoryURL?.appendingPathComponent("issues")
    }
    public static var releasesURL: URL? {
        githubRepositoryURL?.appendingPathComponent("releases")
    }
}
