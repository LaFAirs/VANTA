import SwiftUI

public struct CertificateCard: View {
    let cert: SigningCertificate
    var appCount: Int = 0
    var onUse: (() -> Void)? = nil
    var onInspect: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil

    public init(cert: SigningCertificate, appCount: Int = 0, onUse: (() -> Void)? = nil,
                onInspect: (() -> Void)? = nil, onRemove: (() -> Void)? = nil) {
        self.cert = cert; self.appCount = appCount
        self.onUse = onUse; self.onInspect = onInspect; self.onRemove = onRemove
    }

    public var body: some View {
        VantaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cert.name).font(.headline)
                    Text("Team \(cert.teamID)").font(.caption).foregroundStyle(VantaDS.secondaryText)
                }
                Spacer()
                StatusPill(cert.status.label, color: cert.status.color)
            }
            HStack(spacing: 16) {
                metric("Expires", "\(cert.daysRemaining) days")
                metric("Apps", "\(appCount)")
            }.padding(.vertical, 4)
            HStack(spacing: 16) {
                if let onUse { Button("Use", action: onUse).foregroundStyle(VantaDS.accent) }
                if let onInspect { Button("Inspect", action: onInspect).foregroundStyle(VantaDS.accent) }
                Spacer()
                if let onRemove { Button("Remove", role: .destructive, action: onRemove) }
            }.font(.subheadline).fontWeight(.medium)
        }.accessibilityElement(children: .contain)
    }

    private func metric(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading) {
            Text(k).font(.caption2).foregroundStyle(VantaDS.secondaryText)
            Text(v).font(.subheadline).fontWeight(.semibold)
        }
    }
}

extension CertificateStatus {
    var label: String {
        switch self {
        case .active: return "Active"
        case .expiringSoon: return "Expiring soon"
        case .expired: return "Expired"
        case .invalid: return "Invalid"
        }
    }
    var color: Color {
        switch self {
        case .active: return VantaDS.success
        case .expiringSoon: return VantaDS.warning
        case .expired, .invalid: return VantaDS.danger
        }
    }
}
