import Foundation

/// Adaptive frame pacer. Tracks an exponential moving average of frame
/// intervals and reports whether the loop is hitting its VSync target.
/// Pure logic, fully unit-tested.
struct FramePacer: Sendable {
    let targetHz: Double
    private var emaInterval: Double
    private var samples: Int

    init(targetHz: Double = 60.0) {
        self.targetHz = targetHz
        self.emaInterval = 1.0 / targetHz
        self.samples = 0
    }

    var targetInterval: Double { 1.0 / self.targetHz }

    var smoothedFps: Double {
        guard self.emaInterval > 0 else { return 0 }
        return 1.0 / self.emaInterval
    }

    var sampleCount: Int { self.samples }

    /// True when the smoothed interval is within 10% of the target.
    var isOnPace: Bool {
        abs(self.emaInterval - self.targetInterval) <= 0.1 * self.targetInterval
    }

    mutating func recordFrame(interval: Double) {
        guard interval > 0, interval < 1.0 else { return }
        self.emaInterval = 0.9 * self.emaInterval + 0.1 * interval
        self.samples += 1
    }

    mutating func reset() {
        self.emaInterval = 1.0 / self.targetHz
        self.samples = 0
    }
}
