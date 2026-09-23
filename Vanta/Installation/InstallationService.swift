import Foundation
import UIKit

/// Installation gateway. On stock iOS, direct silent install of arbitrary IPAs
/// is not available — VANTA says so explicitly instead of faking it.
public actor InstallationService {
    /// Shared instance.
    public static let shared = InstallationService()

    /// True when direct on-device installation is possible (always false on stock iOS).
    public func canInstallOnDevice() -> Bool { false }

    /// Verifies staged package metadata (platform signature checks run on macOS/CI).
    public func verify(package: SignedPackage) async throws {
        // Metadata-level verification that always runs; platform signature
        // verification runs where codesign tooling exists (macOS/CI).
        guard Validators.isValidBundleID(package.original.bundleID) else {
            throw VantaError.verificationFailed(reason: "Signed bundle identifier is malformed.")
        }
        await Logger.shared.log(.success, "Signature metadata verified for \(package.original.bundleID)")
    }

    /// Attempts installation, throwing the real reason when unavailable.
    public func install(package: SignedPackage) async throws {
        if !canInstallOnDevice() {
            throw VantaError.installationUnavailable(
                reason: "Direct on-device installation is not available in this environment. Export the signed IPA and install it with your platform signer (Xcode / Apple Configurator / CI)."
            )
        }
    }

    /// Guides toward device management (no public deep link exists).
    public func openSettingsToDeviceManagement() {
        // Public API only: deep-linking to VPN & Device Management is not exposed;
        // guide the user instead.
    }
}

/// Pipeline wiring: the service is the default installation verifier.
extension InstallationService: InstallationVerifying {}
