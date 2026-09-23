import SwiftUI

/// Card describing a managed app with lifecycle actions.
public struct AppCard: View {
    /// The app to display.
    let app: ManagedApp
    /// Install handler.
    var onInstall: (() -> Void)?
    /// Refresh handler.
    var onRefresh: (() -> Void)?
    /// Uninstall handler.
    var onDelete: (() -> Void)?
    /// Details handler.
    var onDetails: (() -> Void)?

    /// Creates an app card.
    public init(
        app: ManagedApp,
        onInstall: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onDetails: (() -> Void)? = nil
    ) {
        self.app = app
        self.onInstall = onInstall
        self.onRefresh = onRefresh
        self.onDelete = onDelete
        self.onDetails = onDetails
    }

    /// Card body.
    public var body: some View {
        VantaCard {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(VantaDS.secondary)
                    .frame(width: 52, height: 52)
                    .overlay(Text(String(self.app.name.prefix(1))).font(.title2).bold()
                        .foregroundStyle(VantaDS.accent))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(self.app.name).font(.headline).lineLimit(1)
                    Text(self.app.bundleID).font(.caption).foregroundStyle(VantaDS.secondaryText).lineLimit(1)
                    Text("\(self.app.version) (\(self.app.build))")
                        .font(.caption2)
                        .foregroundStyle(VantaDS.secondaryText)
                }
                Spacer()
                StatusPill(self.app.status.label, color: self.pillColor)
            }
            HStack(spacing: 12) {
                self.action("Install", system: "arrow.down.circle", handler: self.onInstall)
                self.action("Refresh", system: "arrow.clockwise.circle", handler: self.onRefresh)
                self.action("Details", system: "info.circle", handler: self.onDetails)
                Spacer()
                if self.onDelete != nil {
                    Button(
                        role: .destructive,
                        action: { self.onDelete?() },
                        label: {
                            Image(systemName: "trash").foregroundStyle(VantaDS.danger)
                        }
                    )
                    .accessibilityLabel("Uninstall \(self.app.name)")
                }
            }
            .font(.subheadline).padding(.top, 4)
        }
    }

    private var pillColor: Color {
        switch self.app.status {
        case .installed: return VantaDS.success
        case .needsRefresh, .expired: return VantaDS.warning
        case .failed: return VantaDS.danger
        default: return VantaDS.accent
        }
    }

    private func action(_ label: String, system: String, handler: (() -> Void)?) -> some View {
        Group {
            if let handler {
                Button(action: handler) {
                    Label(label, systemImage: system).foregroundStyle(VantaDS.accent)
                }
                .accessibilityLabel("\(label) \(self.app.name)")
            }
        }
    }
}
