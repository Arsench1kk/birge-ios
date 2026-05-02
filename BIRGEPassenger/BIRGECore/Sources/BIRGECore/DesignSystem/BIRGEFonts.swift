import SwiftUI

public enum BIRGEFonts {
    public static let heroNumber = Font.system(
        .largeTitle,
        design: .rounded,
        weight: .bold
    )
    public static let title = Font.system(
        .title2,
        design: .default,
        weight: .semibold
    )
    public static let sectionTitle = Font.system(
        .headline,
        design: .default,
        weight: .semibold
    )
    public static let body = Font.system(
        .body,
        design: .default,
        weight: .regular
    )
    public static let bodyMedium = Font.system(
        .body,
        design: .default,
        weight: .medium
    )
    public static let subtext = Font.system(
        .subheadline,
        design: .default,
        weight: .regular
    )
    public static let caption = Font.system(
        .caption,
        design: .default,
        weight: .regular
    )
    public static let captionBold = Font.system(
        .caption,
        design: .default,
        weight: .semibold
    )
    public static let otpDigit = Font.system(
        .title,
        design: .monospaced,
        weight: .semibold
    )
    public static let verifyCode = Font.system(
        size: 48,
        weight: .bold,
        design: .monospaced
    )
}
