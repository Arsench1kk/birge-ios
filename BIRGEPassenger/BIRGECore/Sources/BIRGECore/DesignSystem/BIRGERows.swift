import SwiftUI

public struct BIRGETextFieldRow: View {
    private let title: String
    private let placeholder: String
    private let systemImage: String?
    private let text: Binding<String>
    private let axis: Axis

    public init(
        title: String,
        placeholder: String = "",
        systemImage: String? = nil,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) {
        self.title = title
        self.placeholder = placeholder
        self.systemImage = systemImage
        self.text = text
        self.axis = axis
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
            Label {
                Text(title)
            } icon: {
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(BIRGEColors.textSecondary)

            TextField(placeholder.isEmpty ? title : placeholder, text: text, axis: axis)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textPrimary)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, BIRGELayout.s)
                .padding(.vertical, BIRGELayout.xs)
                .liquidGlass(
                    .card,
                    tint: BIRGEColors.brandPrimary.opacity(0.015),
                    isInteractive: true
                )
        }
    }
}

public struct BIRGEListRow: View {
    private let title: String
    private let subtitle: String?
    private let systemImage: String
    private let tint: Color
    private let accessoryText: String?
    private let showsChevron: Bool
    private let action: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color = BIRGEColors.brandPrimary,
        accessoryText: String? = nil,
        showsChevron: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.accessoryText = accessoryText
        self.showsChevron = showsChevron
        self.action = action
    }

    public var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .contentShape(Rectangle())
    }

    private var rowContent: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: systemImage)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusXS))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(title)
                    .font(BIRGEFonts.body)
                    .foregroundStyle(BIRGEColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: BIRGELayout.xxs)

            if let accessoryText {
                Text(accessoryText)
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .lineLimit(1)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textTertiary)
            }
        }
        .padding(.vertical, BIRGELayout.xxxs)
    }
}

public struct BIRGESectionHeader: View {
    private let title: String
    private let subtitle: String?
    private let systemImage: String?
    private let tint: Color

    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        tint: Color = BIRGEColors.brandPrimary
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            HStack(spacing: BIRGELayout.xxs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
            }

            if let subtitle {
                Text(subtitle)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
