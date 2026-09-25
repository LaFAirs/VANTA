import Foundation

/// Priority-sorted pending-interrupt queue. Sources raise interrupts by ID;
/// the CPU drains the highest-priority pending one per timeslice.
final class InterruptController: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: [Int: Int] = [:]

    /// Raises an interrupt. Higher `priority` wins when draining.
    func raise(id: Int, priority: Int = 0) {
        self.lock.lock()
        defer { self.lock.unlock() }
        let current = self.pending[id] ?? Int.min
        self.pending[id] = max(current, priority)
    }

    func clear(id: Int) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.pending.removeValue(forKey: id)
    }

    func clearAll() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.pending.removeAll()
    }

    /// Removes and returns the highest-priority pending interrupt ID, if any.
    func takeHighestPriority() -> Int? {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let best = self.pending.max(by: { lhs, rhs in lhs.value < rhs.value }) else {
            return nil
        }
        self.pending.removeValue(forKey: best.key)
        return best.key
    }

    var pendingCount: Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.pending.count
    }
}
