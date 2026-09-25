import AVFoundation
import Foundation

/// Low-latency output abstraction over AVAudioEngine. The emulation loop
/// pushes 16-bit mono PCM blocks into `submit`; the engine pulls from the
/// ring via a source node. Silence is rendered on underrun (no glitches).
final class AudioEngine: @unchecked Sendable {
    static let sampleRate: Double = 48_000.0

    private let lock = NSLock()
    private var engine: AVAudioEngine?
    private var source: AVAudioSourceNode?
    private let frames: RingBuffer<[Int16]>
    private var volume: Float = 1.0
    private var running = false

    init(bufferBlocks: Int = 8) {
        self.frames = RingBuffer(capacity: max(2, bufferBlocks))
    }

    var isRunning: Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.running
    }

    func setVolume(_ value: Float) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.volume = min(1.0, max(0.0, value))
        self.engine?.mainMixerNode.outputVolume = self.volume
    }

    func submit(_ pcm: [Int16]) {
        self.frames.write(pcm)
    }

    func clear() {
        self.frames.clear()
    }

    @discardableResult
    func start() -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        if self.running { return true }
        let engine = AVAudioEngine()
        let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Self.sampleRate,
            channels: 1,
            interleaved: true
        )
        guard let format else {
            Logger.shared.log(.error, subsystem: "Audio", message: "PCM format unavailable.")
            return false
        }
        let queue = self.frames
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            let list = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buffer = list.first else { return noErr }
            let capacity = Int(frameCount)
            let raw = buffer.mData?.assumingMemoryBound(to: Int16.self)
            var written = 0
            while written < capacity {
                guard let block = queue.read() else { break }
                let take = min(block.count, capacity - written)
                if let raw {
                    for index in 0 ..< take {
                        raw[written + index] = block[index]
                    }
                }
                written += take
            }
            if let raw, written < capacity {
                for index in written ..< capacity {
                    raw[index] = 0
                }
            }
            buffer.mDataByteSize = UInt32(capacity * MemoryLayout<Int16>.size)
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = self.volume
        do {
            try engine.start()
        } catch {
            Logger.shared.log(.error, subsystem: "Audio", message: "Engine start failed: \(error).")
            return false
        }
        self.engine = engine
        self.source = node
        self.running = true
        Logger.shared.log(.info, subsystem: "Audio", message: "Engine started at 48 kHz mono.")
        return true
    }

    func stop() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.engine?.stop()
        if let node = self.source {
            self.engine?.detach(node)
        }
        self.engine = nil
        self.source = nil
        self.running = false
        self.frames.clear()
    }
}
