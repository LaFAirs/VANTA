import Foundation

/// Central, honest configuration. No hardcoded secrets.
/// Maintainer: set your GitHub identity here; the app reads it at runtime.
public enum DeveloperConfig {
    /// Product name.
    public static let appName = "VANTA"
    /// One-line pitch.
    public static let tagline = "Advanced iOS & iPadOS Sideloading."
    /// Marketing version (CI overrides per tag).
    public static let appVersion = "1.0.0"
    /// Build number (CI overrides per run).
    public static let buildNumber = "100"

    /// GitHub username for About page, links, and avatar loading.
    public static let githubUsername = "LaFAirs"

    /// GitHub profile URL.
    public static var githubProfileURL: URL? {
        URL(string: "https://github.com/\(githubUsername)")
    }

    /// GitHub repository URL.
    public static var githubRepositoryURL: URL? {
        URL(string: "https://github.com/\(githubUsername)/VANTA")
    }

    /// GitHub API user URL.
    public static var githubAPIUserURL: URL? {
        URL(string: "https://api.github.com/users/\(githubUsername)")
    }

    /// Documentation folder URL.
    public static var documentationURL: URL? {
        githubRepositoryURL?.appendingPathComponent("tree/main/Documentation")
    }

    /// Issues URL.
    public static var issuesURL: URL? {
        githubRepositoryURL?.appendingPathComponent("issues")
    }

    /// Releases URL.
    public static var releasesURL: URL? {
        githubRepositoryURL?.appendingPathComponent("releases")
    }
}
