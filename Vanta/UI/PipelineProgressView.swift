import SwiftUI

/// Animated pipeline progress: Idle → Processing → Signing → Verifying → Installing → Success.
public struct PipelineProgressView: View {
    /// Pipeline phases.
    public enum Phase: String, CaseIterable, Sendable {
        /// Not started.
        case idle
        /// Working.
        case processing
        /// Signing.
        case signing
        /// Verifying.
        case verifying
        /// Installing.
        case installing
        /// Done.
        case success

        /// Human-readable label.
        var label: String { self.rawValue.capitalized }
    }

    /// Current phase.
    let phase: Phase
    /// Overall progress, 0…1.
    let progress: Double

    /// Creates a progress view.
    public init(phase: Phase, progress: Double) {
        self.phase = phase
        self.progress = progress
    }

    /// Progress body.
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ForEach(Phase.allCases.filter { $0 != .idle }, id: \.self) { step in
                    Circle()
                        .fill(self.color(for: step))
                        .frame(width: 10, height: 10)
                        .scaleEffect(step == self.phase ? 1.35 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: self.phase)
                        .accessibilityHidden(true)
                    if step != .success {
                        Rectangle().fill(VantaDS.cardBorder).frame(height: 1)
                    }
                }
            }
            HStack {
                Text(self.phase.label).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(Int(self.progress * 100))%").font(.caption).foregroundStyle(VantaDS.secondaryText)
            }
            ProgressView(value: self.progress)
                .tint(VantaDS.accent)
                .accessibilityLabel("Progress: \(self.phase.label), \(Int(self.progress * 100)) percent")
        }
        .padding()
        .background(VantaDS.cardBackground)
    }

    private func color(for step: Phase) -> Color {
        let order = Phase.allCases
        guard let current = order.firstIndex(of: step) else {
            return VantaDS.cardBorder
        }
        guard let active = order.firstIndex(of: self.phase) else {
            return VantaDS.cardBorder
        }
        if step == .success && self.phase == .success { return VantaDS.success }
        return current <= active ? VantaDS.accent : VantaDS.cardBorder
    }
}
