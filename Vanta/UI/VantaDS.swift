import SwiftUI

/// VANTA Design System — dark-first, Apple-like, minimal blue glow.
public enum VantaDS {
    /// App background.
    public static let background = Color(hex: 0x05070A)
    /// Secondary surfaces.
    public static let secondary = Color(hex: 0x0B1018)
    /// Card surfaces.
    public static let card = Color(hex: 0x101722)
    /// Card borders.
    public static let cardBorder = Color.white.opacity(0.08)
    /// Electric-blue accent.
    public static let accent = Color(hex: 0x2E7CF6)
    /// Soft blue glow for accents.
    public static let accentGlow = Color(hex: 0x2E7CF6).opacity(0.35)
    /// Success green.
    public static let success = Color(hex: 0x30D158)
    /// Warning amber.
    public static let warning = Color(hex: 0xFF9F0A)
    /// Danger red.
    public static let danger = Color(hex: 0xFF453A)
    /// Primary text.
    public static let primaryText = Color.white
    /// Secondary text.
    public static let secondaryText = Color(hex: 0x9AA4B2)

    /// Standard corner radius.
    public static let corner: CGFloat = 16
    /// Standard card padding.
    public static let cardPadding: CGFloat = 16

    /// Card background with border.
    public static var cardBackground: some View {
        RoundedRectangle(cornerRadius: self.corner, style: .continuous)
            .fill(self.card)
            .overlay(
                RoundedRectangle(cornerRadius: self.corner, style: .continuous)
                    .stroke(self.cardBorder, lineWidth: 1)
            )
    }
}

// MARK: - Hex init

/// Hex color helper.
extension Color {
    /// Creates a color from a hex value.
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Components

/// Standard content card.
public struct VantaCard<Content: View>: View {
    private let content: Content

    /// Creates a card.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// Card body.
    public var body: some View {
        self.content
            .padding(VantaDS.cardPadding)
            .background(VantaDS.cardBackground)
    }
}

/// Primary call-to-action button.
public struct VantaPrimaryButton: View {
    /// Button title.
    let title: String
    /// Tap handler.
    let action: () -> Void

    /// Creates a primary button.
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    /// Button body.
    public var body: some View {
        Button(action: self.action) {
            Text(self.title).fontWeight(.semibold).frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(VantaDS.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: VantaDS.accentGlow, radius: 12, y: 4)
        }
        .accessibilityLabel(self.title)
    }
}

/// Uppercase status pill.
public struct StatusPill: View {
    /// Status text.
    let text: String
    /// Pill color.
    let color: Color

    /// Creates a status pill.
    public init(_ text: String, color: Color = VantaDS.accent) {
        self.text = text
        self.color = color
    }

    /// Pill body.
    public var body: some View {
        Text(self.text.uppercased())
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(self.color.opacity(0.15))
            .foregroundStyle(self.color)
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(self.text)")
    }
}

/// Honest placeholder for unimplemented features.
public struct ComingSoon: View {
    /// Feature description.
    let feature: String

    /// Creates a placeholder.
    public init(_ feature: String) {
        self.feature = feature
    }

    /// Placeholder body.
    public var body: some View {
        VantaCard {
            VStack(spacing: 8) {
                Image(systemName: "hammer.fill").foregroundStyle(VantaDS.secondaryText)
                Text("Coming Soon").font(.headline)
                Text(self.feature).font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                    .multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity).padding(.vertical, 8)
        }
    }
}

/// User-facing error card with remedy action.
public struct VantaErrorCard: View {
    /// The error to display.
    let error: VantaError
    /// Retry handler.
    var retry: (() -> Void)?

    /// Creates an error card.
    public init(_ error: VantaError, retry: (() -> Void)?) {
        self.error = error
        self.retry = retry
    }

    /// Card body.
    public var body: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(VantaDS.warning)
                    Text(self.error.title).font(.headline)
                }
                Text(self.error.reason).font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                if let retry {
                    Button(self.error.remedy, action: retry)
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(VantaDS.accent)
                }
            }
        }.accessibilityElement(children: .combine)
    }
}
