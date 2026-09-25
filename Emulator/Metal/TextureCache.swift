import Foundation
import Metal

/// Bounded Metal texture cache keyed by descriptor string. Evicts least
/// recently inserted entries beyond capacity. Single-owner: create and use
/// on the render thread.
final class TextureCache: @unchecked Sendable {
    private let lock = NSLock()
    private let device: MTLDevice
    private let capacity: Int
    private var entries: [(key: String, texture: MTLTexture)] = []
    private var hits: Int = 0
    private var misses: Int = 0

    init(device: MTLDevice, capacity: Int = 64) {
        self.device = device
        self.capacity = max(1, capacity)
    }

    func texture(width: Int, height: Int, pixelFormat: MTLPixelFormat) -> MTLTexture? {
        let key = "\(width)x\(height)-\(pixelFormat.rawValue)"
        self.lock.lock()
        defer { self.lock.unlock() }
        if let found = self.entries.first(where: { $0.key == key }) {
            self.hits += 1
            return found.texture
        }
        self.misses += 1
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: max(1, width),
            height: max(1, height),
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .private
        guard let texture = self.device.makeTexture(descriptor: descriptor) else { return nil }
        self.entries.append((key: key, texture: texture))
        while self.entries.count > self.capacity {
            self.entries.removeFirst()
        }
        return texture
    }

    func clear() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.entries.removeAll()
        self.hits = 0
        self.misses = 0
    }

    func statistics() -> (hits: Int, misses: Int, entries: Int) {
        self.lock.lock()
        defer { self.lock.unlock() }
        return (self.hits, self.misses, self.entries.count)
    }
}
