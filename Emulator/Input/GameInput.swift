import Foundation

/// Full Switch-like button set for touch and physical controllers.
enum GameButton: String, Sendable, CaseIterable, Codable {
    case a, b, x, y
    case dpadUp, dpadDown, dpadLeft, dpadRight
    case l, r, zl, zr
    case plus, minus, home, capture
    case leftStickClick, rightStickClick
}

/// One input frame: pressed buttons plus both stick axes in -1 ... 1.
struct GameInput: Sendable, Equatable {
    var pressed: Set<GameButton> = []
    var leftStick: SIMD2<Float> = SIMD2<Float>(0, 0)
    var rightStick: SIMD2<Float> = SIMD2<Float>(0, 0)

    mutating func set(_ button: GameButton, pressed: Bool) {
        if pressed {
            self.pressed.insert(button)
        } else {
            self.pressed.remove(button)
        }
    }

    func isPressed(_ button: GameButton) -> Bool {
        self.pressed.contains(button)
    }

    static func clampedStick(x: Float, y: Float) -> SIMD2<Float> {
        let vector = SIMD2<Float>(x, y)
        let length = min(1.0, (vector.x * vector.x + vector.y * vector.y).squareRoot())
        guard length > 0.0001 else { return SIMD2<Float>(0, 0) }
        return vector / max(1.0, (vector.x * vector.x + vector.y * vector.y).squareRoot())
    }
}
