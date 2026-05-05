import SwiftUI

public struct BIRGERouteMetric: Identifiable, Equatable {
    public let id: String
    public let systemImage: String
    public let text: String

    public init(id: String? = nil, systemImage: String, text: String) {
        self.systemImage = systemImage
        self.text = text
        self.id = id ?? "\(systemImage)-\(text)"
    }
}

public struct BIRGERouteSummaryCard: View {
    private let origin: String
    private let destination: String
    private let metrics: [BIRGERouteMetric]
    private let tint: Color

    public init(
        origin: String,
        destination: String,
        metrics: [BIRGERouteMetric] = [],
        tint: Color = BIRGEColors.brandPrimary
    ) {
        self.origin = origin
        self.destination = destination
        self.metrics = metrics
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                routePoint(origin, color: BIRGEColors.success)
                Rectangle()
                    .fill(tint.opacity(0.28))
                    .frame(width: 1.5, height: 16)
                    .padding(.leading, 3)
                routePoint(destination, color: BIRGEColors.danger)
            }

            if !metrics.isEmpty {
                HStack(spacing: BIRGELayout.s) {
                    ForEach(metrics) { metric in
                        Label(metric.text, systemImage: metric.systemImage)
                            .lineLimit(1)
                    }
                }
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: tint.opacity(0.04))
    }

    private func routePoint(_ title: String, color: Color) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

public struct BIRGERideStatusSheet: View {
    private let title: String
    private let subtitle: String
    private let systemImage: String
    private let tint: Color

    public init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color = BIRGEColors.brandPrimary
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        BIRGEGlassSheet {
            HStack(alignment: .top, spacing: BIRGELayout.xs) {
                Image(systemName: systemImage)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .liquidGlass(.button, tint: tint.opacity(0.08))

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(title)
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(subtitle)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.bottom, BIRGELayout.m)
        }
    }
}

public struct BIRGEOfferCard: View {
    private let title: String
    private let subtitle: String
    private let systemImage: String
    private let metrics: [BIRGERouteMetric]
    private let primaryTitle: String
    private let secondaryTitle: String?
    private let primaryAction: () -> Void
    private let secondaryAction: (() -> Void)?

    public init(
        title: String,
        subtitle: String,
        systemImage: String = "car.fill",
        metrics: [BIRGERouteMetric] = [],
        primaryTitle: String,
        secondaryTitle: String? = nil,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.metrics = metrics
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            HStack(alignment: .top, spacing: BIRGELayout.xs) {
                Image(systemName: systemImage)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 44, height: 44)
                    .liquidGlass(
                        .button,
                        tint: BIRGEColors.brandPrimary.opacity(0.08)
                    )

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(title)
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(subtitle)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !metrics.isEmpty {
                HStack(spacing: BIRGELayout.xs) {
                    ForEach(metrics) { metric in
                        Label(metric.text, systemImage: metric.systemImage)
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textPrimary)
            }

            HStack(spacing: BIRGELayout.xs) {
                if let secondaryTitle, let secondaryAction {
                    BIRGESecondaryButton(title: secondaryTitle, action: secondaryAction)
                }

                BIRGEPrimaryButton(title: primaryTitle, action: primaryAction)
            }
        }
        .padding(BIRGELayout.m)
        .liquidGlass(
            .card,
            tint: BIRGEColors.brandPrimary.opacity(0.045),
            isInteractive: true
        )
    }
}
