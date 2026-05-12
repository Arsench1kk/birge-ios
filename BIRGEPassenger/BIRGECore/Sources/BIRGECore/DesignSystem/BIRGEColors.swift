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

    public static let passengerBackground = Color("PassengerBackground")
    public static let passengerSurface = Color("PassengerSurface")
    public static let passengerSurfaceElevated = Color("PassengerSurfaceElevated")
    public static let passengerSurfaceSubtle = Color("PassengerSurfaceSubtle")
    public static let routeCanvasBackground = Color("RouteCanvasBackground")
    public static let borderSubtle = Color("BorderSubtle")
    public static let background = Color("PassengerBackground")
    public static let surfacePrimary = Color("PassengerSurface")
    public static let surfaceGrouped = Color("PassengerSurfaceSubtle")
    public static let surfaceElevated = Color("PassengerSurfaceElevated")
    public static let overlay = Color.black.opacity(0.4)

    // MARK: - Text

    public static let textPrimary = Color("TextPrimary")
    public static let textSecondary = Color("TextSecondary")
    public static let textTertiary = Color("TextTertiary")
    public static let textDisabled = Color("TextDisabled")
    public static let textOnBrand = Color("TextOnBrand")

    // MARK: - Payments

    public static let paymentApplePay = Color("PaymentApplePay")
    public static let paymentKaspi = Color("PaymentKaspi")
    public static let paymentCard = Color("PaymentCard")

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
