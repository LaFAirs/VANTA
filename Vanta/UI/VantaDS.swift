import SwiftUI

/// VANTA Design System — dark-first, Apple-like, minimal blue glow.
public enum VantaDS {
    // Palette (spec: #05070A bg, #0B1018 secondary, #101722 cards, electric blue)
    public static let background = Color(hex: 0x05070A)
    public static let secondary = Color(hex: 0x0B1018)
    public static let card = Color(hex: 0x101722)
    public static let cardBorder = Color.white.opacity(0.08)
    public static let accent = Color(hex: 0x2E7CF6)          // electric blue
    public static let accentGlow = Color(hex: 0x2E7CF6).opacity(0.35)
    public static let success = Color(hex: 0x30D158)
    public static let warning = Color(hex: 0xFF9F0A)
    public static let danger = Color(hex: 0xFF453A)
    public static let primaryText = Color.white
    public static let secondaryText = Color(hex: 0x9AA4B2)

    public static let corner: CGFloat = 16
    public static let cardPadding: CGFloat = 16

    public static var cardBackground: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(card)
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(cardBorder, lineWidth: 1))
    }
}

// MARK: - Hex init

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

// MARK: - Components

public struct VantaCard<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content
            .padding(VantaDS.cardPadding)
            .background(VantaDS.cardBackground)
    }
}

public struct VantaPrimaryButton: View {
    let title: String
    let action: () -> Void
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            Text(title).fontWeight(.semibold).frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(VantaDS.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: VantaDS.accentGlow, radius: 12, y: 4)
        }
        .accessibilityLabel(title)
    }
}

public struct StatusPill: View {
    let text: String
    let color: Color
    public init(_ text: String, color: Color = VantaDS.accent) {
        self.text = text; self.color = color
    }
    public var body: some View {
        Text(text.uppercased())
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(text)")
    }
}

public struct ComingSoon: View {
    let feature: String
    public init(_ feature: String) { self.feature = feature }
    public var body: some View {
        VantaCard {
            VStack(spacing: 8) {
                Image(systemName: "hammer.fill").foregroundStyle(VantaDS.secondaryText)
                Text("Coming Soon").font(.headline)
                Text(feature).font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                    .multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity).padding(.vertical, 8)
        }
    }
}

public struct VantaErrorCard: View {
    let error: VantaError
    var retry: (() -> Void)?
    public init(_ error: VantaError, retry: (() -> Void)? = nil) {
        self.error = error; self.retry = retry
    }
    public var body: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(VantaDS.warning)
                    Text(error.title).font(.headline)
                }
                Text(error.reason).font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                if let retry {
                    Button(error.remedy, action: retry)
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(VantaDS.accent)
                }
            }
        }.accessibilityElement(children: .combine)
    }
}
