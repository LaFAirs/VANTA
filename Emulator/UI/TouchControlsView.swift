import SwiftUI
import UIKit

/// Virtual Switch-like controls: both sticks, face buttons, D-pad, triggers
/// and system buttons. Buttons come from the active TouchLayout (movable,
/// scalable, opacity, haptics); sticks are fixed bottom-left/right.
struct TouchControlsView: View {
    @EnvironmentObject private var state: EmulatorAppState
    @State private var pressed: Set<GameButton> = []
    @State private var leftStick: SIMD2<Float> = SIMD2<Float>(0, 0)
    @State private var rightStick: SIMD2<Float> = SIMD2<Float>(0, 0)

    var body: some View {
        GeometryReader { _ in
            ZStack {
                HStack {
                    self.stick(isLeft: true)
                    Spacer()
                    self.stick(isLeft: false)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                ForEach(self.layout().buttons, id: \.button) { item in
                    self.touchButton(item: item)
                }
            }
        }
        .allowsHitTesting(true)
    }

    private func layout() -> TouchLayout {
        self.state.touch.activeLayout()
    }

    private func touchButton(item: TouchButtonLayout) -> some View {
        let diameter = item.diameter * self.layout().buttonScale
        return Text(self.shortLabel(for: item.button))
            .font(.headline)
            .frame(width: diameter, height: diameter)
            .background((self.pressed.contains(item.button) ? Color.blue : Color.gray)
                .opacity(self.layout().opacity))
            .clipShape(Circle())
            .offset(x: self.edgeOffsetX(item: item), y: item.offsetY)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in self.press(item.button) }
                    .onEnded { _ in self.release(item.button) }
            )
    }

    private func edgeOffsetX(item: TouchButtonLayout) -> Double {
        item.offsetX - 24
    }

    private func stick(isLeft: Bool) -> some View {
        let size: Double = 120 * self.layout().leftStickScale
        return ZStack {
            Circle()
                .fill(Color.gray.opacity(self.layout().opacity))
                .frame(width: size, height: size)
            Circle()
                .fill(Color.blue.opacity(0.8))
                .frame(width: size * 0.45, height: size * 0.45)
                .offset(
                    x: Double(isLeft ? self.leftStick.x : self.rightStick.x) * size * 0.28,
                    y: Double(isLeft ? self.leftStick.y : self.rightStick.y) * size * 0.28
                )
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let vector = SIMD2<Float>(Float(value.translation.width), Float(value.translation.height))
                    let stick = GameInput.clampedStick(x: vector.x / Float(size / 2), y: vector.y / Float(size / 2))
                    if isLeft {
                        self.leftStick = stick
                    } else {
                        self.rightStick = stick
                    }
                }
                .onEnded { _ in
                    if isLeft {
                        self.leftStick = SIMD2<Float>(0, 0)
                    } else {
                        self.rightStick = SIMD2<Float>(0, 0)
                    }
                }
        )
    }

    private func press(_ button: GameButton) {
        if !self.pressed.contains(button), self.layout().hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        self.pressed.insert(button)
    }

    private func release(_ button: GameButton) {
        self.pressed.remove(button)
    }

    private func shortLabel(for button: GameButton) -> String {
        switch button {
        case .a: return "A"
        case .b: return "B"
        case .x: return "X"
        case .y: return "Y"
        case .plus: return "+"
        case .minus: return "−"
        case .home: return "H"
        case .capture: return "C"
        case .l: return "L"
        case .r: return "R"
        case .zl: return "ZL"
        case .zr: return "ZR"
        case .dpadUp: return "▲"
        case .dpadDown: return "▼"
        case .dpadLeft: return "◀"
        case .dpadRight: return "▶"
        case .leftStickClick: return "L3"
        case .rightStickClick: return "R3"
        }
    }
}
