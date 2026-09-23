import XCTest
@testable import Vanta

final class CertificateTests: XCTestCase {
    func testStatusThresholds() {
        let now = Date()
        XCTAssertEqual(CertificateParser.status(for: now.addingTimeInterval(-10), now: now), .expired)
        XCTAssertEqual(CertificateParser.status(for: now.addingTimeInterval(86400 * 5), now: now), .expiringSoon)
        XCTAssertEqual(CertificateParser.status(for: now.addingTimeInterval(86400 * 90), now: now), .active)
    }

    func testValidateRejectsExpired() {
        let claim = CertificateParser.Claim(commonName: "Apple Development",
                                            teamID: "ABC123",
                                            expiresAt: Date().addingTimeInterval(-100))
        XCTAssertThrowsError(try CertificateParser.validate(claim)) { e in
            guard case VantaError.certificateExpired = e as? VantaError else {
                return XCTFail("expected expired")
            }
        }
    }

    func testValidateAcceptsActive() throws {
        let claim = CertificateParser.Claim(commonName: "Apple Development",
                                            teamID: "ABC123",
                                            expiresAt: Date().addingTimeInterval(86400 * 60))
        let cert = try CertificateParser.validate(claim)
        XCTAssertEqual(cert.teamID, "ABC123")
        XCTAssertEqual(cert.status, .active)
    }

    func testProfileMatchExactAndWildcard() {
        let exact = ProvisioningProfile(name: "P", appID: "TEAM.com.example.app",
                                        teamID: "TEAM", expiresAt: Date().addingTimeInterval(99999))
        XCTAssertTrue(exact.matches(bundleID: "com.example.app"))
        XCTAssertFalse(exact.matches(bundleID: "com.other.app"))
        let wild = ProvisioningProfile(name: "W", appID: "TEAM.com.example.*",
                                       teamID: "TEAM", expiresAt: Date().addingTimeInterval(99999))
        XCTAssertTrue(wild.matches(bundleID: "com.example.app"))
        XCTAssertTrue(wild.matches(bundleID: "com.example.app.ext"))
        XCTAssertFalse(wild.matches(bundleID: "com.other.app"))
    }
}
