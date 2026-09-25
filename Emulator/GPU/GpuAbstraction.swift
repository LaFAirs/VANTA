import Foundation

/// Internal render resolution, independent of the display size.
struct RenderResolution: Sendable, Equatable {
    var width: Int
    var height: Int

    static let native = RenderResolution(width: 1280, height: 720)

    var pixelCount: Int { self.width * self.height }
}

/// Minimal GPU interface the emulation loop talks to. The Metal renderer
/// below implements it; a null renderer is used for headless tests.
protocol GpuDevice: Sendable {
    var resolution: RenderResolution { get }
    func setResolution(_ resolution: RenderResolution)
    func beginFrame()
    func endFrame()
    func framesPresented() -> UInt64
}

/// No-op implementation for logic tests without a GPU.
final class NullGpu: GpuDevice, Sendable {
    private let lock = NSLock()
    private var currentResolution: RenderResolution = .native
    private var presented: UInt64 = 0

    var resolution: RenderResolution {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.currentResolution
    }

    func setResolution(_ resolution: RenderResolution) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.currentResolution = resolution
    }

    func beginFrame() {}

    func endFrame() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.presented &+= 1
    }

    func framesPresented() -> UInt64 {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.presented
    }
}
