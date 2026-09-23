import XCTest
@testable import Vanta

final class SigningChecksTests: XCTestCase {
    private func cert(team: String = "TEAM") -> SigningCertificate {
        SigningCertificate(name: "Apple Development", teamID: team,
                           expiresAt: Date().addingTimeInterval(86400 * 30))
    }
    private func profile(appID: String = "TEAM.com.example.app", team: String = "TEAM") -> ProvisioningProfile {
        ProvisioningProfile(name: "Dev", appID: appID, teamID: team,
                            expiresAt: Date().addingTimeInterval(86400 * 30),
                            entitlements: ["application-identifier", "get-task-allow"])
    }

    func testHappyPath() {
        XCTAssertNoThrow(try SigningChecks.verify(certificate: cert(), profile: profile(),
                                                  bundleID: "com.example.app",
                                                  requestedEntitlements: ["get-task-allow"]))
    }

    func testBundleMismatchHasActionableError() {
        XCTAssertThrowsError(try SigningChecks.verify(
            certificate: cert(), profile: profile(),
            bundleID: "com.other.app", requestedEntitlements: [])) { e in
            guard let v = e as? VantaError, case .profileMismatch(let b, _) = v else {
                return XCTFail("expected profileMismatch")
            }
            XCTAssertEqual(b, "com.other.app")
            XCTAssertTrue(v.reason.contains("Bundle Identifier"))
            XCTAssertEqual(v.remedy, "Choose another profile")
        }
    }

    func testEntitlementsMismatchListsMissing() {
        XCTAssertThrowsError(try SigningChecks.verify(
            certificate: cert(), profile: profile(),
            bundleID: "com.example.app",
            requestedEntitlements: ["get-task-allow", "aps-environment"])) { e in
            guard let ve = e as? VantaError, case VantaError.entitlementsMismatch(let m) = ve else {
                return XCTFail("expected entitlementsMismatch")
            }
            XCTAssertEqual(m, ["aps-environment"])
        }
    }

    func testTeamMismatchNeverFaked() {
        XCTAssertThrowsError(try SigningChecks.verify(
            certificate: cert(team: "TEAM-A"), profile: profile(team: "TEAM-B"),
            bundleID: "com.example.app", requestedEntitlements: [])) { e in
            guard let ve = e as? VantaError, case VantaError.signingFailed = ve else {
                return XCTFail("expected signingFailed")
            }
        }
    }

    func testSignerAvailabilityHonest() {
        XCTAssertTrue(LocalCertificateSigner().availability.isReady)
        XCTAssertFalse(PersonalTeamSigner().availability.isReady)
        XCTAssertFalse(RemoteSigner().availability.isReady)
    }
}
