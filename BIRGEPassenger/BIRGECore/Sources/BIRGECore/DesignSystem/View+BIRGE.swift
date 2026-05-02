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
}
