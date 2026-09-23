import SwiftUI

/// Card describing a signing certificate with lifecycle actions.
public struct CertificateCard: View {
    /// The certificate to display.
    let cert: SigningCertificate
    /// Number of apps using it.
    var appCount: Int = 0
    /// Use handler.
    var onUse: (() -> Void)?
    /// Inspect handler.
    var onInspect: (() -> Void)?
    /// Remove handler.
    var onRemove: (() -> Void)?

    /// Creates a certificate card.
    public init(
        cert: SigningCertificate,
        appCount: Int = 0,
        onUse: (() -> Void)?,
        onInspect: (() -> Void)?,
        onRemove: (() -> Void)?
    ) {
        self.cert = cert
        self.appCount = appCount
        self.onUse = onUse
        self.onInspect = onInspect
        self.onRemove = onRemove
    }

    /// Card body.
    public var body: some View {
        VantaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.cert.name).font(.headline)
                    Text("Team \(self.cert.teamID)")
                        .font(.caption)
                        .foregroundStyle(VantaDS.secondaryText)
                }
                Spacer()
                StatusPill(self.cert.status.label, color: self.cert.status.color)
            }
            HStack(spacing: 16) {
                self.metric("Expires", "\(self.cert.daysRemaining()) days")
                self.metric("Apps", "\(self.appCount)")
            }.padding(.vertical, 4)
            HStack(spacing: 16) {
                if let onUse {
                    Button("Use", action: onUse).foregroundStyle(VantaDS.accent)
                }
                if let onInspect {
                    Button("Inspect", action: onInspect).foregroundStyle(VantaDS.accent)
                }
                Spacer()
                if let onRemove {
                    Button("Remove", role: .destructive, action: onRemove)
                }
            }.font(.subheadline).fontWeight(.medium)
        }.accessibilityElement(children: .contain)
    }

    private func metric(_ key: String, _ value: String) -> some View {
        VStack(alignment: .leading) {
            Text(key).font(.caption2).foregroundStyle(VantaDS.secondaryText)
            Text(value).font(.subheadline).fontWeight(.semibold)
        }
    }
}

/// Display helpers for certificate states.
extension CertificateStatus {
    /// Human-readable label.
    var label: String {
        switch self {
        case .active: return "Active"
        case .expiringSoon: return "Expiring soon"
        case .expired: return "Expired"
        case .invalid: return "Invalid"
        }
    }

    /// Accent color for the state.
    var color: Color {
        switch self {
        case .active: return VantaDS.success
        case .expiringSoon: return VantaDS.warning
        case .expired, .invalid: return VantaDS.danger
        }
    }
}
