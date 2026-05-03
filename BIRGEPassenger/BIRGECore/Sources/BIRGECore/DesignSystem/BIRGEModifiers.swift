import SwiftUI

// MARK: - Card Style

public struct BIRGECardStyle: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(BIRGEColors.surfacePrimary)
            .cornerRadius(BIRGELayout.radiusM)
    }
}

// MARK: - Sheet Handle

public struct BIRGESheetHandle: View {
    public init() {}

    public var body: some View {
        Capsule()
            .fill(Color.primary.opacity(0.2))
            .frame(
                width: BIRGELayout.sheetHandleWidth,
                height: BIRGELayout.sheetHandleHeight
            )
    }
}

// MARK: - Status Pill

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

// MARK: - Pressable Button Style

public struct BIRGEPressableButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Primary Button

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
            .shadow(color: BIRGEColors.brandPrimary.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(BIRGEPressableButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }
}

// MARK: - Destructive Button

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
        .buttonStyle(BIRGEPressableButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }
}

// MARK: - Secondary Button

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
        .buttonStyle(BIRGEPressableButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }
}

// MARK: - Toast

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
        case .success: return BIRGEColors.success
        case .error:   return BIRGEColors.danger
        case .info:    return BIRGEColors.info
        case .warning: return BIRGEColors.warning
        }
    }

    private var iconName: String {
        switch style {
        case .success: return "checkmark.circle.fill"
        case .error:   return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        case .warning: return "timer"
        }
    }
}

// MARK: - Liquid Glass Modifier

/// Универсальный Liquid Glass modifier.
/// Использует .ultraThinMaterial + tint overlay + subtle border.
/// Совместим с iOS 15+; на iOS 26+ можно заменить на .glassEffect().
public struct BIRGEGlassModifier: ViewModifier {
    public enum Variant {
        case card    // RoundedRectangle radius 24
        case pill    // Capsule
        case button  // RoundedRectangle radius 16
    }

    public let variant: Variant
    public let tint: Color

    public init(variant: Variant = .card, tint: Color = .clear) {
        self.variant = variant
        self.tint = tint
    }

    public func body(content: Content) -> some View {
        content
            .background(glassBackground)
    }

    @ViewBuilder
    private var glassBackground: some View {
        switch variant {
        case .card:
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusL).fill(tint))
                .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusL).stroke(Color.white.opacity(0.18), lineWidth: 1))
        case .pill:
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(tint))
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
        case .button:
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).fill(tint))
                .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
    }
}

public extension View {
    /// Применить Liquid Glass стиль.
    func liquidGlass(
        _ variant: BIRGEGlassModifier.Variant = .card,
        tint: Color = .clear
    ) -> some View {
        modifier(BIRGEGlassModifier(variant: variant, tint: tint))
    }
}

// MARK: - Glass Card Modifier

public struct BIRGEGlassCardModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .liquidGlass(.card)
            .shadow(color: BIRGEColors.brandPrimary.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Glass Bottom Sheet

/// Стандартный нижний стеклянный лист BIRGE с drag handle.
public struct BIRGEGlassSheet<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.primary.opacity(0.2))
                .frame(width: BIRGELayout.sheetHandleWidth, height: BIRGELayout.sheetHandleHeight)
                .padding(.top, BIRGELayout.xxs)
                .padding(.bottom, BIRGELayout.xs)

            content
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: BIRGELayout.radiusL,
                topTrailingRadius: BIRGELayout.radiusL
            )
            .fill(.ultraThinMaterial)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: BIRGELayout.radiusL,
                    topTrailingRadius: BIRGELayout.radiusL
                )
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .ignoresSafeArea(edges: .bottom)
        )
        .shadow(color: BIRGEColors.brandPrimary.opacity(0.07), radius: 24, y: -8)
    }
}

// MARK: - AI Pill

/// AI notification pill — "AI нашёл 3 коридора рядом".
public struct BIRGEAIPill: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: BIRGELayout.xxxs) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BIRGEColors.brandPrimary)
            Text(text)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.brandPrimary)
        }
        .padding(.horizontal, BIRGELayout.s)
        .padding(.vertical, BIRGELayout.xxs)
        .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.07))
        .shadow(color: BIRGEColors.brandPrimary.opacity(0.15), radius: 8, y: 4)
    }
}

// MARK: - Match Badge

/// AI-совпадение в процентах (98%, 87% и т.д.)
public struct BIRGEMatchBadge: View {
    let percent: Int

    public init(_ percent: Int) {
        self.percent = percent
    }

    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))
            Text("\(percent)% совпадение")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(BIRGEColors.brandPrimary)
        .padding(.horizontal, BIRGELayout.xs)
        .padding(.vertical, BIRGELayout.xxxs)
        .background(BIRGEColors.brandPrimary.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(BIRGEColors.brandPrimary.opacity(0.2), lineWidth: 1))
    }
}
