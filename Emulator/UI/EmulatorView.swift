import MetalKit
import SwiftUI

/// UIViewRepresentable hosting the triple-buffered Metal view.
struct MetalHostView: UIViewRepresentable {
    let onRenderer: (MetalRenderer?) -> Void

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.colorPixelFormat = .bgra8Unorm
        if let renderer = MetalRenderer(metalView: view) {
            context.coordinator.renderer = renderer
            self.onRenderer(renderer)
        } else {
            self.onRenderer(nil)
        }
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var renderer: MetalRenderer?
    }
}

/// Emulation screen: Metal output, transport controls, touch overlay and an
/// optional developer HUD (FPS, frame time, memory, cache stats).
struct EmulatorView: View {
    @EnvironmentObject private var state: EmulatorAppState
    @State private var renderer: MetalRenderer?
    @State private var rendererMissing = false
    @State private var hud = PerformanceSnapshot(
        fps: 0,
        frameTimeMs: 0,
        usedMemoryMB: 0,
        availableMemoryMB: 0,
        cpuLoadPercent: nil,
        gpuLoadPercent: nil
    )
    @State private var cacheStats = (hits: 0, misses: 0, entryCount: 0)

    var body: some View {
        ZStack {
            MetalHostView { created in
                self.renderer = created
                self.rendererMissing = created == nil
            }
            .ignoresSafeArea()
            TouchControlsView()
            VStack {
                HStack {
                    Text(self.state.statusText)
                        .padding(8)
                        .background(.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                    if self.state.settings.developerMode || self.state.settings.showFps {
                        self.hudView
                    }
                }
                .padding()
                Spacer()
                self.transportBar
            }
        }
        .alert("Notice", isPresented: self.$rendererMissing) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Metal is unavailable on this device; emulation runs headless.")
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            self.state.core.runFrameSlice()
            self.state.controllers.poll()
            self.state.refreshStatus()
            if let renderer = self.renderer {
                self.hud = renderer.performance()
            }
            self.cacheStats = self.state.shaderCache.statistics()
        }
    }

    private var hudView: some View {
        VStack(alignment: .trailing) {
            Text(String(format: "%.0f FPS", self.hud.fps))
            Text(String(format: "%.2f ms", self.hud.frameTimeMs))
            Text(String(format: "%.0f MB", self.hud.usedMemoryMB))
            Text("Shader \(self.cacheStats.hits)/\(self.cacheStats.misses)")
        }
        .font(.caption.monospaced())
        .padding(8)
        .background(.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var transportBar: some View {
        HStack(spacing: 24) {
            Button {
                self.state.core.pause()
                self.state.refreshStatus()
            } label: {
                Label("Pause", systemImage: "pause.fill")
            }
            Button {
                self.state.core.resume()
                self.state.refreshStatus()
            } label: {
                Label("Resume", systemImage: "play.fill")
            }
            Button(role: .destructive) {
                self.state.core.stop()
                self.state.refreshStatus()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
        }
        .labelStyle(.iconOnly)
        .font(.title)
        .padding()
        .background(.black.opacity(0.6))
        .clipShape(Capsule())
        .padding(.bottom)
    }
}
