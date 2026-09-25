import Foundation

/// Honest on-device metrics. Only values that are actually measured are
/// exposed: frame rate / frame time (measured), memory footprint (from the
/// OS). CPU/GPU utilisation are NOT available without private APIs and are
/// therefore reported as unavailable instead of faked.
struct PerformanceSnapshot: Sendable {
    let fps: Double
    let frameTimeMs: Double
    let usedMemoryMB: Double
    let availableMemoryMB: Double
    let cpuLoadPercent: Double?
    let gpuLoadPercent: Double?

    var hasCpuLoad: Bool { self.cpuLoadPercent != nil }
    var hasGpuLoad: Bool { self.gpuLoadPercent != nil }
}

/// Rolling performance monitor fed by the render loop. Call `recordFrame`
/// once per presented frame; read `snapshot()` for UI display.
final class PerformanceMonitor: @unchecked Sendable {
    private let lock = NSLock()
    private var lastTime: Date?
    private var emaFrameTime: Double = 1.0 / 60.0
    private var frames: Int = 0
    private var fpsWindowStart: Date = Date()
    private var measuredFps: Double = 0

    func recordFrame(now: Date = Date()) {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let last = self.lastTime {
            let delta = now.timeIntervalSince(last)
            if delta > 0, delta < 1.0 {
                self.emaFrameTime = 0.9 * self.emaFrameTime + 0.1 * delta
            }
        }
        self.lastTime = now
        self.frames += 1
        let window = now.timeIntervalSince(self.fpsWindowStart)
        if window >= 0.5 {
            self.measuredFps = Double(self.frames) / window
            self.frames = 0
            self.fpsWindowStart = now
        }
    }

    func reset() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.lastTime = nil
        self.emaFrameTime = 1.0 / 60.0
        self.frames = 0
        self.measuredFps = 0
        self.fpsWindowStart = Date()
    }

    func snapshot() -> PerformanceSnapshot {
        self.lock.lock()
        let fps = self.measuredFps
        let frameTime = self.emaFrameTime
        self.lock.unlock()
        let availableBytes = Double(os_proc_available_memory())
        let physicalBytes = Double(ProcessInfo.processInfo.physicalMemory)
        let usedMB = max(0, (physicalBytes - availableBytes)) / 1_048_576.0
        return PerformanceSnapshot(
            fps: fps,
            frameTimeMs: frameTime * 1000.0,
            usedMemoryMB: usedMB,
            availableMemoryMB: availableBytes / 1_048_576.0,
            cpuLoadPercent: nil,
            gpuLoadPercent: nil
        )
    }
}
