import Foundation

/// Lifecycle of the emulation loop.
enum SchedulerState: String, Sendable {
    case stopped
    case running
    case paused
}

/// Cooperative tick scheduler. The CPU interpreter calls `tick()` once per
/// executed instruction batch; GPU/audio hosts poll `state` and
/// `totalTicks` to pace their work. No threads are spawned here.
final class Scheduler: Sendable {
    private let lock = NSLock()
    private var currentState: SchedulerState = .stopped
    private var ticks: UInt64 = 0
    private var targetHz: Double = 60.0

    var state: SchedulerState {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.currentState
    }

    var totalTicks: UInt64 {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.ticks
    }

    func configure(targetHz: Double) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.targetHz = max(1.0, targetHz)
    }

    func start() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.currentState = .running
    }

    func pause() {
        self.lock.lock()
        defer { self.lock.unlock() }
        if self.currentState == .running {
            self.currentState = .paused
        }
    }

    func resume() {
        self.lock.lock()
        defer { self.lock.unlock() }
        if self.currentState == .paused {
            self.currentState = .running
        }
    }

    func stop() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.currentState = .stopped
        self.ticks = 0
    }

    func tick(count: UInt64 = 1) {
        self.lock.lock()
        defer { self.lock.unlock() }
        if self.currentState == .running {
            self.ticks &+= count
        }
    }

    /// Nanoseconds one frame should take at the configured rate.
    var frameBudgetNs: UInt64 {
        self.lock.lock()
        defer { self.lock.unlock() }
        return UInt64(1_000_000_000.0 / self.targetHz)
    }
}
