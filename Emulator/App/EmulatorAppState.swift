import Combine
import Foundation

/// Persistent user settings: graphics, audio, performance profile and
/// developer mode. Stored in UserDefaults under a dedicated suite prefix.
@MainActor
final class EmulatorSettings: ObservableObject {
    @Published var internalResolution: Int = 720
    @Published var upscalingEnabled: Bool = false
    @Published var vsyncEnabled: Bool = true
    @Published var audioVolume: Double = 0.8
    @Published var audioBufferBlocks: Int = 8
    @Published var performanceProfile: String = "Balanced"
    @Published var developerMode: Bool = false
    @Published var showFps: Bool = false

    private let lock = NSLock()
    private let prefix = "switchemu.settings."

    init() {
        self.internalResolution = self.loadInt("resolution", defaultValue: 720)
        self.upscalingEnabled = self.loadBool("upscaling", defaultValue: false)
        self.vsyncEnabled = self.loadBool("vsync", defaultValue: true)
        self.audioVolume = self.loadDouble("volume", defaultValue: 0.8)
        self.audioBufferBlocks = self.loadInt("audioBlocks", defaultValue: 8)
        self.performanceProfile = self.loadString("profile", defaultValue: "Balanced")
        self.developerMode = self.loadBool("developer", defaultValue: false)
        self.showFps = self.loadBool("showFps", defaultValue: false)
    }

    func persist() {
        self.lock.lock()
        defer { self.lock.unlock() }
        let defaults = UserDefaults.standard
        defaults.set(self.internalResolution, forKey: self.prefix + "resolution")
        defaults.set(self.upscalingEnabled, forKey: self.prefix + "upscaling")
        defaults.set(self.vsyncEnabled, forKey: self.prefix + "vsync")
        defaults.set(self.audioVolume, forKey: self.prefix + "volume")
        defaults.set(self.audioBufferBlocks, forKey: self.prefix + "audioBlocks")
        defaults.set(self.performanceProfile, forKey: self.prefix + "profile")
        defaults.set(self.developerMode, forKey: self.prefix + "developer")
        defaults.set(self.showFps, forKey: self.prefix + "showFps")
    }

    private func loadInt(_ key: String, defaultValue: Int) -> Int {
        let value = UserDefaults.standard.integer(forKey: self.prefix + key)
        return value == 0 ? defaultValue : value
    }

    private func loadBool(_ key: String, defaultValue: Bool) -> Bool {
        guard UserDefaults.standard.object(forKey: self.prefix + key) != nil else { return defaultValue }
        return UserDefaults.standard.bool(forKey: self.prefix + key)
    }

    private func loadDouble(_ key: String, defaultValue: Double) -> Double {
        guard UserDefaults.standard.object(forKey: self.prefix + key) != nil else { return defaultValue }
        return UserDefaults.standard.double(forKey: self.prefix + key)
    }

    private func loadString(_ key: String, defaultValue: String) -> String {
        UserDefaults.standard.string(forKey: self.prefix + key) ?? defaultValue
    }
}

/// App-wide state owned by the SwiftUI scene: core, settings, filesystem,
/// saves, input and the currently selected library file.
@MainActor
final class EmulatorAppState: ObservableObject {
    let core = EmulatorCore()
    let settings = EmulatorSettings()
    let filesystem = SandboxFS()
    let saves = SaveManager()
    let touch = TouchController()
    let controllers = GameControllerBridge()
    let shaderCache = ShaderCacheStore()

    @Published var libraryFiles: [URL] = []
    @Published var selectedFile: URL?
    @Published var lastError: String?
    @Published var isImporting = false
    @Published var statusText: String = "Idle"

    init() {
        self.controllers.installObservers()
        self.refreshLibrary()
    }

    func refreshLibrary() {
        self.libraryFiles = self.filesystem.listLibrary()
    }

    func refreshStatus() {
        switch self.core.currentStatus() {
        case .idle:
            self.statusText = "Idle"
        case .running:
            self.statusText = "Running"
        case .paused:
            self.statusText = "Paused"
        case .failed:
            self.statusText = "Failed"
            self.lastError = self.core.currentFailure()
        }
    }
}
