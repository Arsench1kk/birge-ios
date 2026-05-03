import SwiftUI

public extension View {
    func birgeCard() -> some View {
        modifier(BIRGECardStyle())
    }

    func birgeTapTarget() -> some View {
        frame(
            minWidth: BIRGELayout.minTapTarget,
            minHeight: BIRGELayout.minTapTarget
        )
    }

    func birgeReduceMotion(_ animation: Animation) -> some View {
        modifier(ReduceMotion(animation: animation))
    }

    /// Стеклянная карточка с тенью — основной строительный блок UI BIRGE.
    func birgeGlassCard() -> some View {
        modifier(BIRGEGlassCardModifier())
    }
}
