import Foundation
import Metal
import MetalKit

/// Triple-buffered Metal renderer with pipeline caching and VSync.
/// Renders a neutral test pattern (NOT game graphics: no Switch GPU
/// emulation exists yet). Frame pacing comes from the MTKView display link.
final class MetalRenderer: NSObject, Sendable, MTKViewDelegate {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let monitor = PerformanceMonitor()
    private let lock = NSLock()
    private var presentedFrames: UInt64 = 0
    private var clearPhase: Double = 0

    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "passthroughVertex"),
              let fragment = library.makeFunction(name: "patternFragment") else {
            Logger.shared.log(.error, subsystem: "Metal", message: "Metal unavailable or shaders missing.")
            return nil
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do {
            self.pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            Logger.shared.log(.error, subsystem: "Metal", message: "Pipeline creation failed: \(error).")
            return nil
        }
        self.device = device
        self.queue = queue
        super.init()
        metalView.device = device
        metalView.delegate = self
        metalView.preferredFramesPerSecond = 60
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        Logger.shared.log(.info, subsystem: "Metal", message: "Renderer ready on \(device.name).")
    }

    func presentedCount() -> UInt64 {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.presentedFrames
    }

    func performance() -> PerformanceSnapshot {
        self.monitor.snapshot()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let buffer = self.queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else {
            return
        }
        self.lock.lock()
        self.clearPhase += 0.01
        let phase = self.clearPhase
        self.lock.unlock()
        pass.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.08 + 0.04 * sin(phase),
            green: 0.10,
            blue: 0.16,
            alpha: 1.0
        )
        encoder.setRenderPipelineState(self.pipeline)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
        self.lock.lock()
        self.presentedFrames &+= 1
        self.lock.unlock()
        self.monitor.recordFrame()
    }
}
