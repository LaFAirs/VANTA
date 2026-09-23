import XCTest
@testable import Vanta

final class ValidatorsTests: XCTestCase {
    func testValidBundleIDs() {
        XCTAssertTrue(Validators.isValidBundleID("com.example.app"))
        XCTAssertTrue(Validators.isValidBundleID("com.vanta.app"))
        XCTAssertFalse(Validators.isValidBundleID("not a bundle"))
        XCTAssertFalse(Validators.isValidBundleID("com..example"))
        XCTAssertFalse(Validators.isValidBundleID(""))
    }

    func testVersionValidation() {
        XCTAssertTrue(Validators.isValidVersion("1.0.0"))
        XCTAssertTrue(Validators.isValidVersion("21.32.1"))
        XCTAssertFalse(Validators.isValidVersion(""))
        XCTAssertFalse(Validators.isValidVersion("1.0-beta"))
        XCTAssertFalse(Validators.isValidVersion(".1.0"))
    }

    func testParseURL() throws {
        let u = try Validators.parseURL("https://example.com/repo.json")
        XCTAssertEqual(u.host, "example.com")
        XCTAssertThrowsError(try Validators.parseURL("not a url"))
        XCTAssertThrowsError(try Validators.parseURL("ftp://example.com/x"))
    }

    func testInsecureRequiresAcknowledgement() throws {
        let http = try Validators.parseURL("http://example.com/repo.json")
        XCTAssertThrowsError(try Validators.requireSecure(http)) { e in
            guard case VantaError.insecureURL = e as? VantaError else {
                return XCTFail("expected insecureURL, got \(e)")
            }
        }
        XCTAssertNoThrow(try Validators.requireSecure(http, acknowledgedInsecure: true))
        let https = try Validators.parseURL("https://example.com/repo.json")
        XCTAssertNoThrow(try Validators.requireSecure(https))
    }
}
