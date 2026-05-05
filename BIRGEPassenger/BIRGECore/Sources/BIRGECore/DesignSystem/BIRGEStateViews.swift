import SwiftUI

public struct BIRGEEmptyState: View {
    private let title: String
    private let message: String
    private let systemImage: String
    private let tint: Color
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        title: String,
        message: String,
        systemImage: String = "tray",
        tint: Color = BIRGEColors.brandPrimary,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.tint = tint
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: BIRGELayout.xs) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(tint)

            Text(title)
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.textPrimary)

            Text(message)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                BIRGESecondaryButton(title: actionTitle, action: action)
                    .padding(.top, BIRGELayout.xxs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(BIRGELayout.l)
        .liquidGlass(.card, tint: tint.opacity(0.025))
    }
}

public struct BIRGEErrorState: View {
    private let title: String
    private let message: String
    private let retryTitle: String?
    private let retry: (() -> Void)?

    public init(
        title: String = "Не удалось загрузить данные",
        message: String,
        retryTitle: String? = nil,
        retry: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retry = retry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Label(title, systemImage: "exclamationmark.triangle.fill")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.danger)

            Text(message)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let retryTitle, let retry {
                Button(retryTitle, action: retry)
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .padding(.top, BIRGELayout.xxxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.danger.opacity(0.045))
    }
}

public struct BIRGELoadingState: View {
    private let title: String
    private let message: String?
    private let minHeight: CGFloat

    public init(
        title: String = "Загружаем",
        message: String? = nil,
        minHeight: CGFloat = 140
    ) {
        self.title = title
        self.message = message
        self.minHeight = minHeight
    }

    public var body: some View {
        VStack(spacing: BIRGELayout.xs) {
            ProgressView()
                .tint(BIRGEColors.brandPrimary)

            Text(title)
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)

            if let message {
                Text(message)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.02))
    }
}
