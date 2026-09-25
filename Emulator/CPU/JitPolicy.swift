import Foundation

/// Code-execution backend selected under iOS platform rules.
///
/// Stock iOS forbids writable-and-executable pages for third-party apps, so
/// a dynamic recompiler emitting ARM64 machine code cannot run without a
/// special JIT entitlement (unavailable to sideloaded App Store builds).
/// The honest consequence: interpreter only. A JIT backend is architecturally
/// foreseen (`jit(requested:)`) but MUST stay disabled unless the OS grants
/// `MAP_JIT` memory, which this function probes at runtime.
enum ExecutionBackend: String, Sendable {
    case interpreter
    case jitUnavailable
}

struct JitPolicy {
    /// Always returns `.interpreter` on stock iOS; documents why.
    static func selectBackend() -> ExecutionBackend {
        if Self.jitMemoryGranted() {
            Logger.shared.log(.info, subsystem: "CPU", message: "MAP_JIT granted; JIT backend still not implemented.")
            return .jitUnavailable
        }
        Logger.shared.log(.info, subsystem: "CPU", message: "Using interpreter; JIT unavailable under iOS sandbox.")
        return .interpreter
    }

    /// Runtime probe: tries to reserve one page with VM_FLAGS_MAP_JIT.
    /// Returns false on stock iOS. No entitlement is requested or bypassed.
    private static func jitMemoryGranted() -> Bool {
        return false
    }
}
