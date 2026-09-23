import XCTest
@testable import Vanta

final class RepositoryValidatorTests: XCTestCase {
    private func manifestData(named name: String = "Test Repo") -> Data {
        """
        {"name":"\(name)","identifier":"com.test.repo","apps":[
          {"name":"Example","bundleIdentifier":"com.example.app","version":"1.2.3",
           "downloadURL":"https://example.com/app.ipa",
           "iconURL":"https://example.com/icon.png",
           "developer":"Example","localizedDescription":"Test app"}
        ]}
        """.data(using: .utf8)!
    }

    func testValidManifest() throws {
        let repo = try RepositoryValidator.validate(
            data: manifestData(),
            sourceURL: URL(string: "https://example.com/repo.json")!)
        XCTAssertEqual(repo.name, "Test Repo")
        XCTAssertEqual(repo.apps.count, 1)
        XCTAssertEqual(repo.apps.first?.bundleIdentifier, "com.example.app")
    }

    func testHTTPWithoutAckThrows() {
        XCTAssertThrowsError(try RepositoryValidator.validate(
            data: manifestData(),
            sourceURL: URL(string: "http://example.com/repo.json")!)) { e in
            guard case VantaError.insecureURL = e as? VantaError else {
                return XCTFail("expected insecureURL")
            }
        }
    }

    func testInvalidBundleIDRejected() {
        let bad = """
        {"name":"R","identifier":"r","apps":[
          {"name":"Bad","bundleIdentifier":"!!!","version":"1.0",
           "downloadURL":"https://example.com/a.ipa"}]}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try RepositoryValidator.validate(
            data: bad, sourceURL: URL(string: "https://example.com/r.json")!)) { e in
            guard case VantaError.repositoryInvalid = e as? VantaError else {
                return XCTFail("expected repositoryInvalid")
            }
        }
    }

    func testMalformedJSONRejected() {
        XCTAssertThrowsError(try RepositoryValidator.validate(
            data: Data("nope".utf8),
            sourceURL: URL(string: "https://example.com/r.json")!))
    }
}
