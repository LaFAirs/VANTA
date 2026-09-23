import SwiftUI

public struct AppCard: View {
    let app: ManagedApp
    var onInstall: (() -> Void)? = nil
    var onRefresh: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onDetails: (() -> Void)? = nil

    public init(app: ManagedApp, onInstall: (() -> Void)? = nil,
                onRefresh: (() -> Void)? = nil, onDelete: (() -> Void)? = nil,
                onDetails: (() -> Void)? = nil) {
        self.app = app; self.onInstall = onInstall; self.onRefresh = onRefresh
        self.onDelete = onDelete; self.onDetails = onDetails
    }

    public var body: some View {
        VantaCard {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(VantaDS.secondary)
                    .frame(width: 52, height: 52)
                    .overlay(Text(String(app.name.prefix(1))).font(.title2).bold().foregroundStyle(VantaDS.accent))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name).font(.headline).lineLimit(1)
                    Text(app.bundleID).font(.caption).foregroundStyle(VantaDS.secondaryText).lineLimit(1)
                    Text("\(app.version) (\(app.build))").font(.caption2).foregroundStyle(VantaDS.secondaryText)
                }
                Spacer()
                StatusPill(app.status.label, color: pillColor)
            }
            HStack(spacing: 12) {
                action("Install", system: "arrow.down.circle", fn: onInstall)
                action("Refresh", system: "arrow.clockwise.circle", fn: onRefresh)
                action("Details", system: "info.circle", fn: onDetails)
                Spacer()
                if onDelete != nil {
                    Button(role: .destructive, action: { onDelete?() }) {
                        Image(systemName: "trash").foregroundStyle(VantaDS.danger)
                    }.accessibilityLabel("Uninstall \(app.name)")
                }
            }
            .font(.subheadline).padding(.top, 4)
        }
    }

    private var pillColor: Color {
        switch app.status {
        case .installed: return VantaDS.success
        case .needsRefresh, .expired: return VantaDS.warning
        case .failed: return VantaDS.danger
        default: return VantaDS.accent
        }
    }

    private func action(_ label: String, system: String, fn: (() -> Void)?) -> some View {
        Group {
            if let fn {
                Button(action: fn) { Label(label, systemImage: system).foregroundStyle(VantaDS.accent) }
                    .accessibilityLabel("\(label) \(app.name)")
            }
        }
    }
}
