import Foundation

/// Position and size of one virtual button, in points relative to the
/// overlay anchor. Freely movable and scalable from the UI.
struct TouchButtonLayout: Sendable, Codable, Equatable {
    var button: GameButton
    var offsetX: Double
    var offsetY: Double
    var diameter: Double
}

/// Named touch layout: button geometries plus shared opacity and haptics.
/// Persisted as JSON in UserDefaults; ships with left/right-handed presets.
struct TouchLayout: Sendable, Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var buttons: [TouchButtonLayout]
    var opacity: Double
    var hapticsEnabled: Bool
    var leftStickScale: Double
    var buttonScale: Double

    static func presetRightHanded() -> TouchLayout {
        TouchLayout(
            id: UUID(),
            name: "Right-handed",
            buttons: [
                TouchButtonLayout(button: .a, offsetX: -70, offsetY: -120, diameter: 64),
                TouchButtonLayout(button: .b, offsetX: -140, offsetY: -70, diameter: 64),
                TouchButtonLayout(button: .x, offsetX: -140, offsetY: -170, diameter: 64),
                TouchButtonLayout(button: .y, offsetX: -210, offsetY: -120, diameter: 64),
                TouchButtonLayout(button: .plus, offsetX: -60, offsetY: -300, diameter: 44),
                TouchButtonLayout(button: .minus, offsetX: 60, offsetY: -300, diameter: 44)
            ],
            opacity: 0.55,
            hapticsEnabled: true,
            leftStickScale: 1.0,
            buttonScale: 1.0
        )
    }

    static func presetLeftHanded() -> TouchLayout {
        var layout = TouchLayout.presetRightHanded()
        layout.id = UUID()
        layout.name = "Left-handed"
        layout.buttons = layout.buttons.map { item in
            TouchButtonLayout(
                button: item.button,
                offsetX: -item.offsetX,
                offsetY: item.offsetY,
                diameter: item.diameter
            )
        }
        return layout
    }
}

/// Stores touch layouts and the active selection. Emits no UI itself.
final class TouchController: @unchecked Sendable {
    private let lock = NSLock()
    private let layoutsKey = "switchemu.touch.layouts"
    private let activeKey = "switchemu.touch.active"

    func layouts() -> [TouchLayout] {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let data = UserDefaults.standard.data(forKey: self.layoutsKey),
              let decoded = try? JSONDecoder().decode([TouchLayout].self, from: data),
              !decoded.isEmpty else {
            return [.presetRightHanded(), .presetLeftHanded()]
        }
        return decoded
    }

    func saveLayouts(_ layouts: [TouchLayout]) {
        guard let data = try? JSONEncoder().encode(layouts) else { return }
        self.lock.lock()
        UserDefaults.standard.set(data, forKey: self.layoutsKey)
        self.lock.unlock()
    }

    func activeLayout() -> TouchLayout {
        let all = self.layouts()
        self.lock.lock()
        defer { self.lock.unlock() }
        if let id = UserDefaults.standard.string(forKey: self.activeKey),
           let match = all.first(where: { $0.id.uuidString == id }) {
            return match
        }
        return all[0]
    }

    func setActiveLayout(id: UUID) {
        self.lock.lock()
        UserDefaults.standard.set(id.uuidString, forKey: self.activeKey)
        self.lock.unlock()
    }
}
