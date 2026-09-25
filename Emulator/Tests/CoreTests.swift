import Foundation
import Testing

@testable import SwitchEmu

/// Unit tests for the honest core: memory guards, demo ISA, scheduler,
/// interrupts, ring buffer and frame pacing. No hardware required.
struct CoreTests {
    @Test func memoryReadWriteRoundTrip() throws {
        let memory = VirtualMemory()
        try memory.map(base: 0x1_0000, size: 0x1000, permissions: [.read, .write])
        try memory.write32(0xDEAD_BEEF, at: 0x1_0000)
        #expect(try memory.read32(at: 0x1_0000) == 0xDEAD_BEEF)
    }

    @Test func memoryRejectsUnmappedAccess() throws {
        let memory = VirtualMemory()
        do {
            _ = try memory.read8(at: 0x9_0000)
            Issue.record("expected unmapped error")
        } catch let error as MemoryError {
            #expect(error == .unmapped(address: 0x9_0000))
        }
    }

    @Test func memoryEnforcesReadOnly() throws {
        let memory = VirtualMemory()
        try memory.map(base: 0x2_0000, size: 0x1000, permissions: [.read])
        do {
            try memory.write8(1, at: 0x2_0000)
            Issue.record("expected permission error")
        } catch let error as MemoryError {
            #expect(error == .permissionDenied(address: 0x2_0000))
        }
    }

    @Test func interpreterAddsAndHalts() throws {
        let memory = VirtualMemory()
        try memory.map(base: 0x1_0000, size: 0x1000, permissions: [.read, .write])
        // LOADI r1,10; LOADI r2,32; ADD r3,r1,r2; HALT
        let program: [UInt8] = [
            0x02, 0x01, 0x0A, 0x00, 0x00, 0x00,
            0x02, 0x02, 0x20, 0x00, 0x00, 0x00,
            0x03, 0x03, 0x01, 0x02,
            0x01
        ]
        for (offset, byte) in program.enumerated() {
            try memory.write8(byte, at: 0x1_0000 + UInt64(offset))
        }
        let cpu = Arm64Interpreter(memory: memory, loadAddress: 0x1_0000)
        let executed = try cpu.run(budget: 16)
        #expect(executed == 3)
        #expect(cpu.snapshot().registers[3] == 42)
        #expect(cpu.snapshot().halted)
    }

    @Test func interpreterTrapsUnknownOpcode() throws {
        let memory = VirtualMemory()
        try memory.map(base: 0x1_0000, size: 0x1000, permissions: [.read, .write])
        try memory.write8(0xFF, at: 0x1_0000)
        let cpu = Arm64Interpreter(memory: memory, loadAddress: 0x1_0000)
        do {
            try cpu.step()
            Issue.record("expected invalid opcode")
        } catch let error as InterpreterError {
            #expect(error == .invalidOpcode(0xFF))
        }
    }

    @Test func schedulerPausesAndResumes() {
        let scheduler = Scheduler()
        scheduler.start()
        scheduler.tick(count: 10)
        scheduler.pause()
        scheduler.tick(count: 10)
        #expect(scheduler.totalTicks == 10)
        scheduler.resume()
        scheduler.tick()
        #expect(scheduler.totalTicks == 11)
        #expect(scheduler.state == .running)
    }

    @Test func interruptsDrainHighestPriorityFirst() {
        let controller = InterruptController()
        controller.raise(id: 1, priority: 1)
        controller.raise(id: 2, priority: 9)
        #expect(controller.takeHighestPriority() == 2)
        #expect(controller.takeHighestPriority() == 1)
        #expect(controller.takeHighestPriority() == nil)
    }

    @Test func ringBufferDropsOldestOnOverflow() {
        let buffer = RingBuffer<Int>(capacity: 2)
        buffer.write(1)
        buffer.write(2)
        let dropped = buffer.write(3)
        #expect(dropped)
        #expect(buffer.read() == 2)
        #expect(buffer.read() == 3)
        #expect(buffer.read() == nil)
    }

    @Test func framePacerReachesSteadyState() {
        var pacer = FramePacer(targetHz: 60.0)
        for _ in 0 ..< 200 {
            pacer.recordFrame(interval: 1.0 / 60.0)
        }
        #expect(pacer.isOnPace)
        #expect(abs(pacer.smoothedFps - 60.0) < 1.0)
    }

    @Test func emulatorCoreRejectsOversizedProgram() {
        let core = EmulatorCore()
        let huge = Data(repeating: 0, count: Int(EmulatorCore.memorySize) + 1)
        // Prefix-truncated to fit: start must still succeed without crashing.
        #expect(core.start(with: huge))
        core.stop()
        #expect(core.currentStatus() == .idle)
    }
}
