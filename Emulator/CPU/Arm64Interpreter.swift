import Foundation

/// General-purpose register file plus program counter for the demo CPU.
/// This models a small educational ISA, NOT ARMv8/Switch execution.
struct CPUState: Sendable {
    static let registerCount = 16

    var registers: [UInt64]
    var programCounter: UInt64
    var halted: Bool
    var executedInstructions: UInt64

    init(loadAddress: UInt64 = 0) {
        self.registers = [UInt64](repeating: 0, count: Self.registerCount)
        self.programCounter = loadAddress
        self.halted = false
        self.executedInstructions = 0
    }

    mutating func reset(loadAddress: UInt64) {
        self.registers = [UInt64](repeating: 0, count: Self.registerCount)
        self.programCounter = loadAddress
        self.halted = false
        self.executedInstructions = 0
    }
}

/// Demo instruction set (1 byte opcode + operands, little-endian):
/// 0x00 NOP, 0x01 HALT, 0x02 LOADI reg,imm32, 0x03 ADD rd,ra,rb,
/// 0x04 SUB rd,ra,rb, 0x05 JUMP addr32, 0x06 JZ reg,addr32.
/// Anything else traps. This is intentionally NOT Switch code execution.
enum InterpreterError: Error, Sendable, Equatable {
    case halted
    case invalidOpcode(UInt8)
    case invalidRegister(UInt8)
    case memoryError
}

/// Single-threaded fetch-decode-execute interpreter for the demo ISA.
/// Drive it with `step()` / `run(budget:)` from the emulation loop.
final class Arm64Interpreter: Sendable {
    private let lock = NSLock()
    private var cpuState: CPUState
    private let memory: VirtualMemory

    init(memory: VirtualMemory, loadAddress: UInt64 = 0) {
        self.memory = memory
        self.cpuState = CPUState(loadAddress: loadAddress)
    }

    func snapshot() -> CPUState {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.cpuState
    }

    func reset(loadAddress: UInt64) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.cpuState.reset(loadAddress: loadAddress)
    }

    /// Executes up to `budget` instructions. Returns executed count.
    func run(budget: Int) throws -> Int {
        var executed = 0
        while executed < budget {
            do {
                try self.step()
                executed += 1
            } catch InterpreterError.halted {
                return executed
            }
        }
        return executed
    }

    func step() throws {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard !self.cpuState.halted else { throw InterpreterError.halted }
        let opcode: UInt8
        do {
            opcode = try self.memory.read8(at: self.cpuState.programCounter)
        } catch {
            throw InterpreterError.memoryError
        }
        switch opcode {
        case 0x00:
            self.cpuState.programCounter &+= 1
        case 0x01:
            self.cpuState.halted = true
        case 0x02:
            let reg = try self.readOperandByte(offset: 1)
            let imm = try self.readOperand32(offset: 2)
            try self.writeRegister(reg, value: UInt64(imm))
            self.cpuState.programCounter &+= 6
        case 0x03, 0x04:
            let dest = try self.readOperandByte(offset: 1)
            let lhs = try self.readRegister(try self.readOperandByte(offset: 2))
            let rhs = try self.readRegister(try self.readOperandByte(offset: 3))
            let result = opcode == 0x03 ? lhs &+ rhs : lhs &- rhs
            try self.writeRegister(dest, value: result)
            self.cpuState.programCounter &+= 4
        case 0x05:
            let target = try self.readOperand32(offset: 1)
            self.cpuState.programCounter = UInt64(target)
        case 0x06:
            let reg = try self.readOperandByte(offset: 1)
            let target = try self.readOperand32(offset: 2)
            if try self.readRegister(reg) == 0 {
                self.cpuState.programCounter = UInt64(target)
            } else {
                self.cpuState.programCounter &+= 6
            }
        default:
            throw InterpreterError.invalidOpcode(opcode)
        }
        self.cpuState.executedInstructions &+= 1
    }

    private func readOperandByte(offset: UInt64) throws -> UInt8 {
        do {
            return try self.memory.read8(at: self.cpuState.programCounter &+ offset)
        } catch {
            throw InterpreterError.memoryError
        }
    }

    private func readOperand32(offset: UInt64) throws -> UInt32 {
        do {
            return try self.memory.read32(at: self.cpuState.programCounter &+ offset)
        } catch {
            throw InterpreterError.memoryError
        }
    }

    private func readRegister(_ index: UInt8) throws -> UInt64 {
        guard Int(index) < CPUState.registerCount else { throw InterpreterError.invalidRegister(index) }
        return self.cpuState.registers[Int(index)]
    }

    private func writeRegister(_ index: UInt8, value: UInt64) throws {
        guard Int(index) < CPUState.registerCount else { throw InterpreterError.invalidRegister(index) }
        self.cpuState.registers[Int(index)] = value
    }
}
