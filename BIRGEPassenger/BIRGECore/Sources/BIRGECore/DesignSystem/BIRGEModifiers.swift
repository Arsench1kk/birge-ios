import SwiftUI

public struct BIRGECardStyle: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(BIRGEColors.surfacePrimary)
            .cornerRadius(BIRGELayout.radiusM)
    }
}

public struct BIRGESheetHandle: View {
    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: BIRGELayout.sheetHandleRadius)
            .fill(BIRGEColors.textTertiary)
            .frame(
                width: BIRGELayout.sheetHandleWidth,
                height: BIRGELayout.sheetHandleHeight
            )
    }
}

public struct BIRGEStatusPill: View {
    private let label: String
    private let color: Color

    public init(label: String, color: Color) {
        self.label = label
        self.color = color
    }

    public var body: some View {
        Text(label)
            .font(BIRGEFonts.captionBold)
            .foregroundColor(BIRGEColors.textOnBrand)
            .padding(.horizontal, BIRGELayout.xs)
            .padding(.vertical, BIRGELayout.xxxs)
            .background(color)
            .clipShape(Capsule())
    }
}

public struct BIRGEPrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(BIRGEColors.textOnBrand)
                } else {
                    Text(title)
                        .font(BIRGEFonts.bodyMedium)
                }
            }
            .foregroundColor(BIRGEColors.textOnBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(BIRGEColors.brandPrimary)
            .cornerRadius(BIRGELayout.radiusM)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }
}

public struct BIRGEDestructiveButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(BIRGEColors.danger)
                } else {
                    Text(title)
                        .font(BIRGEFonts.bodyMedium)
                }
            }
            .foregroundColor(BIRGEColors.danger)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(BIRGEColors.danger.opacity(0.12))
            .cornerRadius(BIRGELayout.radiusM)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }
}

public struct BIRGESecondaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(BIRGEColors.brandPrimary)
                } else {
                    Text(title)
                        .font(BIRGEFonts.bodyMedium)
                }
            }
            .foregroundColor(BIRGEColors.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(BIRGEColors.surfacePrimary)
            .overlay(
                RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                    .stroke(BIRGEColors.brandPrimary.opacity(0.28), lineWidth: 1)
            )
            .cornerRadius(BIRGELayout.radiusM)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }
}

public struct BIRGEToast: View {
    public enum ToastStyle {
        case success
        case error
        case info
        case warning
    }

    private let message: String
    private let style: ToastStyle

    public init(message: String, style: ToastStyle) {
        self.message = message
        self.style = style
    }

    public var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: iconName)
                .font(BIRGEFonts.captionBold)
                .foregroundColor(BIRGEColors.textOnBrand)

            Text(message)
                .font(BIRGEFonts.subtext)
                .foregroundColor(BIRGEColors.textOnBrand)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: BIRGELayout.xxs)
        }
        .padding(.horizontal, BIRGELayout.s)
        .padding(.vertical, BIRGELayout.xs)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
    }

    private var backgroundColor: Color {
        switch style {
        case .success:
            return BIRGEColors.success
        case .error:
            return BIRGEColors.danger
        case .info:
            return BIRGEColors.info
        case .warning:
            return BIRGEColors.warning
        }
    }

    private var iconName: String {
        switch style {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "timer"
        }
    }
}
