import XCTest
@testable import Vanta

/// Thread-safe progress collector for Sendable test closures.
private final class ProgressSink: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var values: [Double] = []

    /// Records a progress fraction.
    func append(_ value: Double) {
        lock.lock()
        values.append(value)
        lock.unlock()
    }
}

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
        // Local signer has no Keychain identity in tests → unavailable (honest).
        XCTAssertFalse(LocalCertificateSigner().availability(certificate: cert(), profile: profile()).isReady)
        XCTAssertFalse(PersonalTeamSigner().availability(certificate: cert(), profile: profile()).isReady)
        XCTAssertFalse(RemoteSigner().availability(certificate: cert(), profile: profile()).isReady)
        XCTAssertEqual(ImportedCertificateSigner()
            .availability(certificate: cert(), profile: profile()).isReady, true)
    }

    func testSignerStagingRejectsMissingFile() async throws {
        let package = try IPAPackage(name: "Example", bundleID: "com.example.app",
                                     version: "1.0", fileURL: nil)
        do {
            _ = try await ImportedCertificateSigner()
                .sign(application: package, certificate: cert(), profile: profile()) { _ in }
            XCTFail("expected ipaNotFound")
        } catch {
            XCTAssertEqual(error as? VantaError, VantaError.ipaNotFound)
        }
    }

    func testSignerStagingCreatesRealFile() async throws {
        let source = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".ipa")
        try Data("fake-ipa-bytes".utf8).write(to: source)
        let package = try IPAPackage(name: "Example", bundleID: "com.example.app",
                                     version: "1.0", fileURL: source)
        let sink = ProgressSink()
        let signed = try await ImportedCertificateSigner()
            .sign(application: package, certificate: cert(), profile: profile()) { sink.append($0) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: signed.signedURL.path))
        XCTAssertEqual(signed.sourceSHA256.count, 64)
        XCTAssertFalse(sink.values.isEmpty)
        try? FileManager.default.removeItem(at: source)
        try? FileManager.default.removeItem(at: signed.signedURL)
    }
}
