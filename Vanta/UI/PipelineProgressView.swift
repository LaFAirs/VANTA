import SwiftUI

/// Animated pipeline progress: Idle → Processing → Signing → Verifying → Installing → Success.
public struct PipelineProgressView: View {
    public enum Phase: String, CaseIterable {
        case idle, processing, signing, verifying, installing, success
        var label: String { rawValue.capitalized }
    }
    let phase: Phase
    let progress: Double  // 0…1

    public init(phase: Phase, progress: Double) {
        self.phase = phase; self.progress = progress
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ForEach(Phase.allCases.filter { $0 != .idle }, id: \.self) { step in
                    Circle()
                        .fill(color(for: step))
                        .frame(width: 10, height: 10)
                        .scaleEffect(step == phase ? 1.35 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: phase)
                        .accessibilityHidden(true)
                    if step != .success { Rectangle().fill(VantaDS.cardBorder).frame(height: 1) }
                }
            }
            HStack {
                Text(phase.label).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(Int(progress * 100))%").font(.caption).foregroundStyle(VantaDS.secondaryText)
            }
            ProgressView(value: progress)
                .tint(VantaDS.accent)
                .accessibilityLabel("Progress: \(phase.label), \(Int(progress * 100)) percent")
        }
        .padding()
        .background(VantaDS.cardBackground)
    }

    private func color(for step: Phase) -> Color {
        let order = Phase.allCases
        guard let a = order.firstIndex(of: step), let b = order.firstIndex(of: phase) else {
            return VantaDS.cardBorder
        }
        if step == .success && phase == .success { return VantaDS.success }
        return a <= b ? VantaDS.accent : VantaDS.cardBorder
    }
}
