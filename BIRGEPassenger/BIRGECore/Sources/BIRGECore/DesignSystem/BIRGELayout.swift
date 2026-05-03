import CoreGraphics

public enum BIRGELayout {
    // MARK: - Spacing

    public static let xxxs: CGFloat = 4
    public static let xxs: CGFloat = 8
    public static let xs: CGFloat = 12
    public static let s: CGFloat = 16
    public static let m: CGFloat = 20
    public static let l: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 40
    public static let xxxl: CGFloat = 48

    // MARK: - Corner Radius

    public static let radiusXS: CGFloat = 8
    public static let radiusS: CGFloat = 12
    public static let radiusM: CGFloat = 16
    public static let radiusL: CGFloat = 24
    public static let radiusFull: CGFloat = 999

    // MARK: - Touch Targets

    public static let minTapTarget: CGFloat = 44

    // MARK: - Bottom Sheet

    public static let sheetHandleWidth: CGFloat = 36
    public static let sheetHandleHeight: CGFloat = 4
    public static let sheetHandleRadius: CGFloat = 2

    // MARK: - Map Overlays

    /// Отступ сверху для элементов поверх карты (ниже статус-бара)
    public static let mapSearchBarTop: CGFloat = 59
    public static let mapSearchBarHeight: CGFloat = 52
}
