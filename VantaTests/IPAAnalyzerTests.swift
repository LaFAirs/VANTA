import XCTest
@testable import Vanta

final class IPAAnalyzerTests: XCTestCase {
    func testAnalyzeValidPlist() throws {
        let plist: [String: Any] = [
            "CFBundleIdentifier": "com.example.app",
            "CFBundleDisplayName": "Example",
            "CFBundleShortVersionString": "21.32.1",
            "CFBundleVersion": "21321",
            "MinimumOSVersion": "17.0"
        ]
        let info = try IPAAnalyzer.analyze(infoPlist: plist)
        XCTAssertEqual(info.name, "Example")
        XCTAssertEqual(info.bundleID, "com.example.app")
        XCTAssertEqual(info.version, "21.32.1")
        XCTAssertEqual(info.build, "21321")
        XCTAssertEqual(info.minimumOS, "17.0")
    }

    func testAnalyzeMissingBundleIDThrows() {
        XCTAssertThrowsError(try IPAAnalyzer.analyze(infoPlist: [:])) { e in
            XCTAssertEqual(e as? VantaError, VantaError.infoPlistMissing)
        }
    }

    func testSupportedArchitectures() throws {
        XCTAssertEqual(try IPAAnalyzer.supportedArchitectures(["arm64"]), ["arm64"])
        XCTAssertThrowsError(try IPAAnalyzer.supportedArchitectures(["x86_64"])) { e in
            guard let ve = e as? VantaError, case VantaError.unsupportedArchitecture = ve else {
                return XCTFail("wrong error \(e)")
            }
        }
    }

    func testEntitlementDiff() {
        XCTAssertEqual(IPAAnalyzer.missingEntitlements(requested: ["a", "b"], granted: ["a", "b", "c"]), [])
        XCTAssertEqual(IPAAnalyzer.missingEntitlements(requested: ["a", "z"], granted: ["a"]), ["z"])
    }
}
