import SwiftUI

public enum BIRGEColors {
    // MARK: - Brand

    public static let brandPrimary = Color("BrandPrimary")
    public static let brandSecondary = Color("BrandSecondary")

    // MARK: - Semantic

    public static let success = Color("Success")
    public static let warning = Color("Warning")
    public static let danger = Color("Danger")
    public static let info = Color("Info")

    // MARK: - Surfaces

    public static let background = Color(.systemBackground)
    public static let surfacePrimary = Color(.secondarySystemBackground)
    public static let surfaceGrouped = Color(.systemGroupedBackground)
    public static let surfaceElevated = Color(.secondarySystemGroupedBackground)
    public static let overlay = Color.black.opacity(0.4)

    // MARK: - Text

    public static let textPrimary = Color(.label)
    public static let textSecondary = Color(.secondaryLabel)
    public static let textTertiary = Color(.tertiaryLabel)
    public static let textDisabled = Color(.quaternaryLabel)
    public static let textOnBrand = Color.white

    // MARK: - Map

    public static let mapTint = Color("BrandPrimary")
    public static let pickupPin = Color("BrandPrimary")
    public static let destinationPin = Color("Danger")

    // MARK: - Legacy aliases

    @available(*, deprecated, message: "Use brandPrimary.")
    public static let blue = brandPrimary

    @available(*, deprecated, message: "Use surfacePrimary.")
    public static let surfaceSecondary = surfacePrimary
}
