import XCTest
@testable import Vanta

final class BackupCryptoTests: XCTestCase {
    func testBackupRoundTrip() async throws {
        let service = BackupService.shared
        let app = ManagedApp(name: "Example", bundleID: "com.example.app", version: "1.0")
        let backup = await service.makeBackupForTest(apps: [app], repos: [])
        let data = try await service.encode(backup)
        let back = try await service.decode(data)
        XCTAssertEqual(back.apps.count, 1)
        XCTAssertEqual(back.apps.first?.bundleID, "com.example.app")
        XCTAssertEqual(back.version, 1)
    }

    func testEncryptDecryptRoundTrip() async throws {
        let service = BackupService.shared
        let plain = Data("vanta-backup".utf8)
        let sealed = try await service.encrypt(plain, passphrase: "correct-horse")
        XCTAssertNotEqual(sealed, plain)
        let opened = try await service.decrypt(sealed, passphrase: "correct-horse")
        XCTAssertEqual(opened, plain)
    }

    func testPrivateKeyExportRefused() async {
        let err = await BackupService.shared.refusePrivateKeyExport()
        guard case VantaError.backupFailed(let reason) = err else {
            return XCTFail("expected backupFailed")
        }
        XCTAssertTrue(reason.contains("never exported"))
    }
}
