import SwiftUI

public struct ReduceMotion: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let animation: Animation

    public init(animation: Animation) {
        self.animation = animation
    }

    public func body(content: Content) -> some View {
        content.transaction { transaction in
            transaction.animation = reduceMotion ? nil : animation
        }
    }
}
