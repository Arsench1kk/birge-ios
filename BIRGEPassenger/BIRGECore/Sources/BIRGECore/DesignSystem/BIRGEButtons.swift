import SwiftUI

public struct BIRGEIconButton: View {
    public enum Style {
        case glass
        case filled
        case subtle
    }

    private let systemImage: String
    private let accessibilityLabel: String
    private let tint: Color
    private let style: Style
    private let role: ButtonRole?
    private let isDisabled: Bool
    private let action: () -> Void

    public init(
        systemImage: String,
        accessibilityLabel: String,
        tint: Color = BIRGEColors.brandPrimary,
        style: Style = .glass,
        role: ButtonRole? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.tint = tint
        self.style = style
        self.role = role
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemImage)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(foreground)
                .frame(
                    width: BIRGELayout.minTapTarget,
                    height: BIRGELayout.minTapTarget
                )
                .background(buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        }
        .buttonStyle(BIRGEPressableButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(accessibilityLabel)
    }

    private var foreground: Color {
        switch style {
        case .filled:
            return BIRGEColors.textOnBrand
        case .glass, .subtle:
            return tint
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .glass:
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .fill(.clear)
                .liquidGlass(
                    .button,
                    tint: tint.opacity(0.08),
                    isInteractive: true
                )
        case .filled:
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .fill(tint)
        case .subtle:
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .fill(tint.opacity(0.12))
        }
    }
}

public struct BIRGEToolbarButton: View {
    private let title: String
    private let systemImage: String
    private let tint: Color
    private let isDisabled: Bool
    private let action: () -> Void

    public init(
        title: String,
        systemImage: String,
        tint: Color = BIRGEColors.brandPrimary,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(tint)
                .frame(
                    minWidth: BIRGELayout.minTapTarget,
                    minHeight: BIRGELayout.minTapTarget
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityLabel(title)
    }
}

public struct BIRGEMapOverlayButton: View {
    private let systemImage: String
    private let accessibilityLabel: String
    private let tint: Color
    private let action: () -> Void

    public init(
        systemImage: String,
        accessibilityLabel: String,
        tint: Color = BIRGEColors.brandPrimary,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        BIRGEIconButton(
            systemImage: systemImage,
            accessibilityLabel: accessibilityLabel,
            tint: tint,
            style: .glass,
            action: action
        )
        .shadow(color: tint.opacity(0.18), radius: 12, y: 6)
    }
}
