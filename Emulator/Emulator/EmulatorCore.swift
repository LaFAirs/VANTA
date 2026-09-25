import Foundation

/// Frontend-facing state of the emulation session.
enum EmulatorStatus: String, Sendable {
    case idle
    case running
    case paused
    case failed
}

/// Owns scheduler, memory, CPU and interrupts and drives the run loop.
/// Game loading is deliberately limited to raw demo binaries mapped at a
/// fixed address; commercial Switch formats are NOT parsed and encrypted
/// content is NOT decrypted (see Filesystem/SandboxFS.swift).
final class EmulatorCore: @unchecked Sendable {
    static let loadAddress: UInt64 = 0x1_0000
    static let memorySize: UInt64 = 0x10_0000

    private let lock = NSLock()
    private var status: EmulatorStatus = .idle
    private var failureMessage: String?

    let scheduler = Scheduler()
    let interrupts = InterruptController()
    let memory = VirtualMemory()
    let logger = Logger.shared
    let monitor = PerformanceMonitor()
    private let cpu: Arm64Interpreter
    private var backend: ExecutionBackend = .interpreter

    init() {
        self.cpu = Arm64Interpreter(memory: self.memory, loadAddress: Self.loadAddress)
    }

    func currentStatus() -> EmulatorStatus {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.status
    }

    func currentFailure() -> String? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.failureMessage
    }

    /// Maps fresh memory, loads a raw demo binary and starts the scheduler.
    /// Returns false and records a user-facing message on any failure.
    @discardableResult
    func start(with program: Data) -> Bool {
        self.lock.lock()
        self.status = .idle
        self.failureMessage = nil
        self.lock.unlock()
        do {
            self.memory.unmap(base: Self.loadAddress)
            try self.memory.map(
                base: Self.loadAddress,
                size: Self.memorySize,
                permissions: [.read, .write]
            )
            let bytes = [UInt8](program.prefix(Int(Self.memorySize)))
            for (offset, byte) in bytes.enumerated() {
                try self.memory.write8(byte, at: Self.loadAddress + UInt64(offset))
            }
            self.cpu.reset(loadAddress: Self.loadAddress)
            self.interrupts.clearAll()
            self.monitor.reset()
            self.backend = JitPolicy.selectBackend()
            self.scheduler.configure(targetHz: 60.0)
            self.scheduler.start()
            self.logger.log(.info, subsystem: "Emu", message: "Started demo program (\(bytes.count) bytes).")
            self.setStatus(.running)
            return true
        } catch {
            self.fail("Start failed: \(error). Returning to library.")
            return false
        }
    }

    /// Executes one frame slice: drains one interrupt, runs the CPU budget.
    func runFrameSlice(instructionBudget: Int = 4096) {
        guard self.currentStatus() == .running else { return }
        if self.interrupts.takeHighestPriority() != nil {
            self.logger.log(.debug, subsystem: "Emu", message: "Serviced pending interrupt.")
        }
        do {
            let executed = try self.cpu.run(budget: instructionBudget)
            self.scheduler.tick(count: UInt64(executed))
            if self.cpu.snapshot().halted {
                self.logger.log(.info, subsystem: "Emu", message: "Program halted; pausing.")
                self.pause()
            }
        } catch {
            self.fail("Execution error: \(error). Returning to library.")
        }
    }

    func pause() {
        self.scheduler.pause()
        self.setStatus(.paused)
    }

    func resume() {
        self.scheduler.resume()
        self.setStatus(.running)
    }

    func stop() {
        self.scheduler.stop()
        self.setStatus(.idle)
        self.logger.log(.info, subsystem: "Emu", message: "Stopped.")
    }

    private func setStatus(_ next: EmulatorStatus) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.status = next
    }

    private func fail(_ message: String) {
        self.lock.lock()
        self.status = .failed
        self.failureMessage = message
        self.lock.unlock()
        self.scheduler.stop()
        self.logger.log(.error, subsystem: "Emu", message: message)
    }
}
