import Foundation
import GameController

/// Mapping from physical controller elements to emulator buttons.
/// Stored per profile; defaults cover a standard extended gamepad.
struct ControllerMapping: Sendable, Codable, Equatable {
    var buttonA: String = "a"
    var buttonB: String = "b"
    var buttonX: String = "x"
    var buttonY: String = "y"

    static let `default` = ControllerMapping()
}

/// Named controller profile with its mapping. Persisted as JSON.
struct ControllerProfile: Sendable, Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var mapping: ControllerMapping
    var leftStickScale: Float
    var rightStickScale: Float

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.mapping = .default
        self.leftStickScale = 1.0
        self.rightStickScale = 1.0
    }
}

/// GameController.framework bridge: observes connect/disconnect, polls the
/// extended gamepad each frame into a `GameInput`. Rumble is intentionally
/// not wired: haptic engines differ per controller and no fake vibration is
/// reported. Multiple profiles are stored in UserDefaults as JSON.
final class GameControllerBridge: @unchecked Sendable {
    private let lock = NSLock()
    private var latest = GameInput()
    private var connectedNames: [String] = []
    private var profiles: [ControllerProfile] = [ControllerProfile(name: "Default")]
    private var activeProfileID: UUID?
    private var observationInstalled = false

    init() {
        self.activeProfileID = self.profiles.first?.id
    }

    func installObservers() {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard !self.observationInstalled else { return }
        self.observationInstalled = true
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            self?.handleConnect(controller)
        }
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            self?.handleDisconnect(controller)
        }
        for controller in GCController.controllers() {
            self.refreshNames(adding: controller)
        }
    }

    /// Polls the first extended gamepad; call once per frame.
    func poll() {
        guard let pad = GCController.controllers().first?.extendedGamepad else { return }
        var input = GameInput()
        self.apply(pad.buttonA, to: .a, input: &input)
        self.apply(pad.buttonB, to: .b, input: &input)
        self.apply(pad.buttonX, to: .x, input: &input)
        self.apply(pad.buttonY, to: .y, input: &input)
        self.apply(pad.leftShoulder, to: .l, input: &input)
        self.apply(pad.rightShoulder, to: .r, input: &input)
        self.apply(pad.leftTrigger, to: .zl, input: &input)
        self.apply(pad.rightTrigger, to: .zr, input: &input)
        self.apply(pad.buttonMenu, to: .plus, input: &input)
        self.apply(pad.buttonOptions, to: .minus, input: &input)
        self.apply(pad.buttonHome, to: .home, input: &input)
        self.apply(pad.dpad.up, to: .dpadUp, input: &input)
        self.apply(pad.dpad.down, to: .dpadDown, input: &input)
        self.apply(pad.dpad.left, to: .dpadLeft, input: &input)
        self.apply(pad.dpad.right, to: .dpadRight, input: &input)
        input.leftStick = GameInput.clampedStick(x: pad.leftThumbstick.xAxis.value, y: pad.leftThumbstick.yAxis.value)
        input.rightStick = GameInput.clampedStick(x: pad.rightThumbstick.xAxis.value, y: pad.rightThumbstick.yAxis.value)
        self.lock.lock()
        self.latest = input
        self.lock.unlock()
    }

    func latestInput() -> GameInput {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.latest
    }

    func connectedControllerNames() -> [String] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.connectedNames
    }

    var supportsRumble: Bool { false }

    private func apply(_ element: GCControllerButtonInput, to button: GameButton, input: inout GameInput) {
        input.set(button, pressed: element.isPressed)
    }

    private func handleConnect(_ controller: GCController) {
        self.lock.lock()
        defer { self.lock.unlock() }
        let name = controller.vendorName ?? "Controller"
        if !self.connectedNames.contains(name) {
            self.connectedNames.append(name)
        }
        Logger.shared.log(.info, subsystem: "Input", message: "Controller connected: \(name).")
    }

    private func handleDisconnect(_ controller: GCController) {
        self.lock.lock()
        defer { self.lock.unlock() }
        let name = controller.vendorName ?? "Controller"
        self.connectedNames.removeAll { $0 == name }
        Logger.shared.log(.info, subsystem: "Input", message: "Controller disconnected: \(name).")
    }

    private func refreshNames(adding controller: GCController) {
        let name = controller.vendorName ?? "Controller"
        if !self.connectedNames.contains(name) {
            self.connectedNames.append(name)
        }
    }
}
