import Foundation

/// Bounded FIFO for PCM frames between the emulation loop (producer) and
/// the audio output callback (consumer). Lock-protected; drop-oldest on
/// overflow so audio never blocks emulation.
final class RingBuffer<Element>: Sendable where Element: Sendable {
    private let lock = NSLock()
    private var storage: [Element?]
    private var head = 0
    private var tail = 0
    private var full = false
    let capacity: Int

    init(capacity: Int) {
        let size = max(1, capacity)
        self.capacity = size
        self.storage = [Element?](repeating: nil, count: size)
    }

    var count: Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.unsafeCount
    }

    var isEmpty: Bool { self.count == 0 }

    /// Appends, overwriting the oldest element when full. Returns true when
    /// an old element had to be dropped.
    @discardableResult
    func write(_ element: Element) -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        var dropped = false
        if self.full {
            self.head = (self.head + 1) % self.capacity
            dropped = true
        }
        self.storage[self.tail] = element
        self.tail = (self.tail + 1) % self.capacity
        self.full = self.head == self.tail
        return dropped
    }

    func read() -> Element? {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard self.unsafeCount > 0 else { return nil }
        let element = self.storage[self.head]
        self.storage[self.head] = nil
        self.head = (self.head + 1) % self.capacity
        self.full = false
        return element
    }

    func clear() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.storage = [Element?](repeating: nil, count: self.capacity)
        self.head = 0
        self.tail = 0
        self.full = false
    }

    private var unsafeCount: Int {
        if self.full { return self.capacity }
        if self.tail >= self.head { return self.tail - self.head }
        return self.capacity - self.head + self.tail
    }
}
