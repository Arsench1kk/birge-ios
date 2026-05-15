import SwiftUI

public enum BIRGEStatusVariant: Sendable {
    case active
    case muted
    case warning

    public var tint: Color {
        switch self {
        case .active:
            return BIRGEColors.success
        case .muted:
            return BIRGEColors.textTertiary
        case .warning:
            return BIRGEColors.warning
        }
    }

    public var systemImage: String {
        switch self {
        case .active:
            return "checkmark.circle.fill"
        case .muted:
            return "pause.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }

    public var accessibilityName: String {
        switch self {
        case .active:
            return "Active"
        case .muted:
            return "Muted"
        case .warning:
            return "Warning"
        }
    }
}

public struct BIRGEStatusDot: View {
    private let variant: BIRGEStatusVariant
    private let accessibilityLabel: String

    public init(
        variant: BIRGEStatusVariant,
        accessibilityLabel: String? = nil
    ) {
        self.variant = variant
        self.accessibilityLabel = accessibilityLabel ?? variant.accessibilityName
    }

    public var body: some View {
        Circle()
            .fill(variant.tint)
            .frame(width: 8, height: 8)
            .accessibilityLabel(accessibilityLabel)
    }
}

public struct BIRGEStatusBadge: View {
    private let label: String
    private let variant: BIRGEStatusVariant
    private let accessibilityLabel: String

    public init(
        _ label: String,
        variant: BIRGEStatusVariant,
        accessibilityLabel: String? = nil
    ) {
        self.label = label
        self.variant = variant
        self.accessibilityLabel = accessibilityLabel ?? "\(variant.accessibilityName): \(label)"
    }

    public static func active(
        _ label: String,
        accessibilityLabel: String? = nil
    ) -> BIRGEStatusBadge {
        BIRGEStatusBadge(label, variant: .active, accessibilityLabel: accessibilityLabel)
    }

    public static func muted(
        _ label: String,
        accessibilityLabel: String? = nil
    ) -> BIRGEStatusBadge {
        BIRGEStatusBadge(label, variant: .muted, accessibilityLabel: accessibilityLabel)
    }

    public static func warning(
        _ label: String,
        accessibilityLabel: String? = nil
    ) -> BIRGEStatusBadge {
        BIRGEStatusBadge(label, variant: .warning, accessibilityLabel: accessibilityLabel)
    }

    public var body: some View {
        Label {
            Text(label)
                .font(BIRGEFonts.caption)
        } icon: {
            Image(systemName: variant.systemImage)
                .font(BIRGEFonts.captionBold)
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(variant.tint)
        .padding(.horizontal, BIRGELayout.xxs)
        .padding(.vertical, BIRGELayout.xxxs)
        .background(
            Capsule()
                .fill(variant.tint.opacity(0.12))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Status Badges") {
    VStack(alignment: .leading, spacing: BIRGELayout.s) {
        HStack(spacing: BIRGELayout.s) {
            BIRGEStatusDot(variant: .active)
            BIRGEStatusDot(variant: .muted)
            BIRGEStatusDot(variant: .warning)
        }

        HStack(spacing: BIRGELayout.xs) {
            BIRGEStatusBadge.active("Active")
            BIRGEStatusBadge.muted("Muted")
            BIRGEStatusBadge.warning("Warning")
        }
    }
    .padding(BIRGELayout.l)
    .background(BIRGEColors.passengerBackground)
}
