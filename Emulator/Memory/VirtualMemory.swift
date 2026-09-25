import Foundation

/// Access permissions of a mapped memory region.
struct MemoryPermissions: OptionSet, Sendable {
    let rawValue: UInt8

    static let read = MemoryPermissions(rawValue: 1 << 0)
    static let write = MemoryPermissions(rawValue: 1 << 1)
    static let execute = MemoryPermissions(rawValue: 1 << 2)
}

/// Errors for guarded memory access.
enum MemoryError: Error, Sendable, Equatable {
    case unmapped(address: UInt64)
    case permissionDenied(address: UInt64)
    case misaligned(address: UInt64)
    case overflow
}

/// One reserved address range with permissions and backing storage.
struct MemoryRegion: Sendable {
    let base: UInt64
    let size: UInt64
    let permissions: MemoryPermissions
    var storage: [UInt8]

    init(base: UInt64, size: UInt64, permissions: MemoryPermissions) {
        self.base = base
        self.size = size
        self.permissions = permissions
        self.storage = [UInt8](repeating: 0, count: Int(size))
    }

    func contains(_ address: UInt64, length: UInt64) -> Bool {
        address >= self.base && length <= self.size && address - self.base <= self.size - length
    }
}

/// Software-modelled virtual address space with regions, permissions and
/// bounds checking. This is a plain bounds-checked model, not OS-level VM.
final class VirtualMemory: @unchecked Sendable {
    private let lock = NSLock()
    private var regions: [MemoryRegion] = []

    var regionCount: Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.regions.count
    }

    func map(base: UInt64, size: UInt64, permissions: MemoryPermissions) throws {
        guard size > 0, base % 0x1000 == 0, size % 0x1000 == 0 else {
            throw MemoryError.misaligned(address: base)
        }
        self.lock.lock()
        defer { self.lock.unlock() }
        for region in self.regions {
            let end = base + size
            let regionEnd = region.base + region.size
            if base < regionEnd, region.base < end {
                throw MemoryError.overflow
            }
        }
        self.regions.append(MemoryRegion(base: base, size: size, permissions: permissions))
        self.regions.sort { lhs, rhs in lhs.base < rhs.base }
    }

    func unmap(base: UInt64) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.regions.removeAll { region in region.base == base }
    }

    func read8(at address: UInt64) throws -> UInt8 {
        let bytes = try self.readBytes(at: address, count: 1)
        return bytes[0]
    }

    func write8(_ value: UInt8, at address: UInt64) throws {
        try self.writeBytes([value], at: address)
    }

    func read32(at address: UInt64) throws -> UInt32 {
        guard address % 4 == 0 else { throw MemoryError.misaligned(address: address) }
        let bytes = try self.readBytes(at: address, count: 4)
        return UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24)
    }

    func write32(_ value: UInt32, at address: UInt64) throws {
        guard address % 4 == 0 else { throw MemoryError.misaligned(address: address) }
        let bytes: [UInt8] = [
            UInt8(value & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 24) & 0xFF)
        ]
        try self.writeBytes(bytes, at: address)
    }

    private func readBytes(at address: UInt64, count: Int) throws -> [UInt8] {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let region = self.regions.first(where: { $0.contains(address, length: UInt64(count)) }) else {
            throw MemoryError.unmapped(address: address)
        }
        guard region.permissions.contains(.read) else {
            throw MemoryError.permissionDenied(address: address)
        }
        let offset = Int(address - region.base)
        return Array(region.storage[offset ..< offset + count])
    }

    private func writeBytes(_ bytes: [UInt8], at address: UInt64) throws {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let index = self.regions.firstIndex(where: { $0.contains(address, length: UInt64(bytes.count)) }) else {
            throw MemoryError.unmapped(address: address)
        }
        guard self.regions[index].permissions.contains(.write) else {
            throw MemoryError.permissionDenied(address: address)
        }
        let offset = Int(address - self.regions[index].base)
        self.regions[index].storage.replaceSubrange(offset ..< offset + bytes.count, with: bytes)
    }
}
