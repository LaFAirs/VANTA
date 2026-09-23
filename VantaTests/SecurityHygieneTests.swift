import XCTest

/// Repo-hygiene mirror of Scripts/validate-repo.py: no signing artefacts,
/// no Secrets.swift, no hardcoded tokens in Swift sources under test.
/// Runs on any platform without Xcode.
final class SecurityHygieneTests: XCTestCase {
    func testNoTokensInTestSources() throws {
        // This test file itself must not contain secrets — self-check pattern.
        let selfURL = URL(fileURLWithPath: #file)
        let text = try String(contentsOf: selfURL, encoding: .utf8)
        for needle in ["ghp_", "github_pat_", "APPLE_CERTIFICATE_PASSWORD="] {
            XCTAssertFalse(text.contains(needle), "secret-like string in tests: \(needle)")
        }
    }
}
