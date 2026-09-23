import XCTest
@testable import Vanta

final class ClockAndCodesTests: XCTestCase {
    func testErrorCodesAreStableAndUnique() {
        let cases: [VantaError] = [
            .invalidURL("x"), .insecureURL(URL(string: "http://example.com")!),
            .ipaNotFound, .ipaCorrupt(reason: "x"), .infoPlistMissing,
            .unsupportedArchitecture("x"), .certificateExpired(name: "n", date: Date()),
            .certificateInvalid(reason: "x"), .profileExpired(name: "n", date: Date()),
            .profileMismatch(bundleID: "a", profile: "b"), .entitlementsMismatch(missing: ["x"]),
            .signerUnavailable("x"), .signingFailed(reason: "x"), .verificationFailed(reason: "x"),
            .installationUnavailable(reason: "x"), .refreshUnavailable(reason: "x"),
            .repositoryInvalid(reason: "x"), .backupFailed(reason: "x"),
            .keychainFailure(reason: "x"), .notAvailable("x"),
        ]
        let codes = cases.map { $0.code }
        XCTAssertEqual(codes.count, 20)
        XCTAssertEqual(Set(codes).count, codes.count, "codes must be unique")
        XCTAssertTrue(codes.allSatisfy { $0.hasPrefix("VANTA_E") })
    }

    func testLocalizedErrorConformance() {
        let error = VantaError.ipaNotFound
        XCTAssertEqual(error.errorDescription, error.title)
        XCTAssertEqual(error.failureReason, error.reason)
        XCTAssertEqual(error.recoverySuggestion, error.remedy)
    }

    func testFixedClockDaysRemaining() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cert = SigningCertificate(name: "Dev", teamID: "TEAM",
                                      expiresAt: now.addingTimeInterval(86400 * 10))
        XCTAssertEqual(cert.daysRemaining(using: FixedClock(now: now)), 10)
    }

    func testManagedAppValidation() {
        XCTAssertThrowsError(try ManagedApp(name: "", bundleID: "com.example.app", version: "1.0"))
        XCTAssertThrowsError(try ManagedApp(name: "X", bundleID: "!!!", version: "1.0"))
        XCTAssertThrowsError(try ManagedApp(name: "X", bundleID: "com.example.app", version: ""))
        XCTAssertNoThrow(try ManagedApp(name: "X", bundleID: "com.example.app", version: "1.0"))
    }

    func testMarkRefreshedHelper() throws {
        var app = try ManagedApp(name: "X", bundleID: "com.example.app", version: "1.0",
                                 status: .expired)
        let frozen = Date(timeIntervalSince1970: 1_700_000_000)
        app.markRefreshed(expiresAt: frozen, clock: FixedClock(now: frozen))
        XCTAssertEqual(app.status, .installed)
        XCTAssertEqual(app.lastRefreshed, frozen)
    }

    func testRepoAppBusinessKeyEquality() {
        let left = RepoApp(name: "A", bundleIdentifier: "com.example.app", version: "1.0",
                           downloadURL: URL(string: "https://example.com/a.ipa")!)
        let right = RepoApp(name: "A", bundleIdentifier: "com.example.app", version: "1.0",
                            downloadURL: URL(string: "https://example.com/a.ipa")!)
        XCTAssertEqual(left, right)
        XCTAssertNotEqual(left.id, right.id, "local identities stay unique")
    }
}
