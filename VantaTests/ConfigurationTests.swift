import XCTest
@testable import Vanta

final class ConfigurationTests: XCTestCase {
    func testBrandingConsistent() {
        XCTAssertEqual(DeveloperConfig.appName, "VANTA")
        XCTAssertTrue(DeveloperConfig.tagline.contains("Sideloading"))
        XCTAssertTrue(Validators.isValidVersion(DeveloperConfig.appVersion))
        XCTAssertFalse(DeveloperConfig.buildNumber.isEmpty)
    }

    func testGitHubURLsDerivedFromUsername() {
        XCTAssertNotNil(DeveloperConfig.githubProfileURL)
        XCTAssertNotNil(DeveloperConfig.githubRepositoryURL)
        XCTAssertTrue(DeveloperConfig.githubRepositoryURL?.absoluteString.contains("VANTA") == true)
    }

    func testErrorMessagesAreHumanReadable() {
        let e = VantaError.profileMismatch(bundleID: "com.example.app", profile: "com.other.app")
        XCTAssertFalse(e.title.isEmpty)
        XCTAssertTrue(e.reason.contains("com.example.app"))
        XCTAssertFalse(e.reason.contains("Error 13"))
        XCTAssertFalse(e.remedy.isEmpty)
    }

    func testAppStatusLabels() {
        XCTAssertEqual(AppStatus.installed.label, "Installed")
        XCTAssertEqual(AppStatus.needsRefresh.label, "Needs refresh")
    }
}
