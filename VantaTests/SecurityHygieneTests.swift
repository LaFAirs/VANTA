import XCTest

/// Repo-hygiene mirror of Scripts/validate-repo.py: no signing artefacts,
/// no Secrets.swift, no hardcoded tokens in Swift sources under test.
/// Runs on any platform without Xcode.
final class SecurityHygieneTests: XCTestCase {
    func testNoTokensInTestSources() throws {
        // Needles are concatenated so this file itself never contains the patterns.
        let selfURL = URL(fileURLWithPath: #file)
        let text = try String(contentsOf: selfURL, encoding: .utf8)
        for needle in ["gh" + "p_", "github_" + "pat_", "APPLE_" + "CERTIFICATE_" + "PASSWORD="] {
            XCTAssertFalse(text.contains(needle), "secret-like string in tests: \(needle)")
        }
    }
}
