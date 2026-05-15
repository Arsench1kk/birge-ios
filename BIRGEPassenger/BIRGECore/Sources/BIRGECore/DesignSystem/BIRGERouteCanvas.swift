import SwiftUI

// MARK: - BIRGERouteCanvas

/// A decorative map-like canvas surface that displays a start node, end node,
/// a connecting route line, and an optional subtle grid overlay.
///
/// Mirrors the `rm-node-canvas` / `rm-route-canvas` mockup pattern from
/// P-03a-route-origin.html and P-03b-route-destination.html.
public struct BIRGERouteCanvas: View {

    // MARK: - Node Role

    /// Whether this canvas represents an origin pick-up or a destination drop-off.
    /// The destination variant tints the selected-node marker with `BIRGEColors.destinationPin`.
    public enum NodeRole {
        case origin
        case destination
    }

    // MARK: - Stored Properties

    /// Short neighbourhood / area label rendered at the bottom-left corner.
    public let areaLabel: String?
    /// Optional title shown above the canvas (e.g., "Where are you boarding?").
    public let title: String?
    /// Optional subtitle / helper copy shown below the title.
    public let subtitle: String?
    /// Controls pin colour for the selected state.
    public let role: NodeRole

    // MARK: - Init

    public init(
        areaLabel: String? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        role: NodeRole = .origin
    ) {
        self.areaLabel = areaLabel
        self.title = title
        self.subtitle = subtitle
        self.role = role
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            if title != nil || subtitle != nil {
                headerView
            }
            canvasView
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            if let title {
                Text(title)
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textPrimary)
            }
            if let subtitle {
                Text(subtitle)
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
        }
        .padding(.horizontal, BIRGELayout.s)
    }

    private var canvasView: some View {
        ZStack(alignment: .bottomLeading) {
            // Grid overlay
            gridLayer

            // Route line connecting start → end node
            routeLine

            // Start node (origin) — always brandPrimary
            BIRGECanvasNodeMarker(
                isSelected: true,
                role: .origin,
                position: .start
            )

            // End node (destination) — tinted by role
            BIRGECanvasNodeMarker(
                isSelected: false,
                role: role,
                position: .end
            )

            // Area label
            if let areaLabel {
                Text(areaLabel)
                    .font(BIRGEFonts.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(BIRGEColors.textTertiary)
                    .padding(.leading, BIRGELayout.s)
                    .padding(.bottom, BIRGELayout.s)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 184)
        .background(canvasBackground)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
        .shadow(color: Color(red: 0.01, green: 0.09, blue: 0.22).opacity(0.08), radius: 17, y: 8)
    }

    // MARK: - Canvas Background

    /// Matches the `rm-node-canvas` gradient: subtle accent-tinted radial + linear gradient.
    private var canvasBackground: some View {
        ZStack {
            BIRGEColors.routeCanvasBackground

            // Accent radial glow at top-right (matches CSS `radial-gradient at 72% 28%`)
            RadialGradient(
                colors: [BIRGEColors.brandPrimary.opacity(0.13), .clear],
                center: UnitPoint(x: 0.72, y: 0.28),
                startRadius: 0,
                endRadius: 80
            )

            // Accent-tinted linear sweep (matches `linear-gradient 135deg`)
            LinearGradient(
                colors: [
                    BIRGEColors.brandPrimary.opacity(0.07),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.64, y: 1)
            )
        }
    }

    // MARK: - Grid Layer

    /// Subtle dot-grid overlay replicating the CSS `background-image` grid lines on `.rm-node-canvas::before`.
    private var gridLayer: some View {
        Canvas { context, size in
            let step: CGFloat = 22
            let color = BIRGEColors.brandPrimary.opacity(0.06)
            var path = Path()

            // Horizontal lines
            var y: CGFloat = 13
            while y < size.height - 13 {
                path.move(to: CGPoint(x: 13, y: y))
                path.addLine(to: CGPoint(x: size.width - 13, y: y))
                y += step
            }
            // Vertical lines
            var x: CGFloat = 13
            while x < size.width - 13 {
                path.move(to: CGPoint(x: x, y: 13))
                path.addLine(to: CGPoint(x: x, y: size.height - 13))
                x += step
            }
            context.stroke(path, with: .color(color), lineWidth: 1)
        }
    }

    // MARK: - Route Line

    /// Horizontal gradient line connecting start → end node.
    /// Mirrors `.rm-node-canvas::after` (`left: 48 right: 42 top: 94`).
    private var routeLine: some View {
        GeometryReader { geo in
            let lineY: CGFloat = geo.size.height * 0.51
            let startX: CGFloat = 48
            let endX: CGFloat = geo.size.width - 42

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            BIRGEColors.borderSubtle,
                            BIRGEColors.brandPrimary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(0, endX - startX), height: 3)
                .clipShape(Capsule())
                .position(x: startX + max(0, endX - startX) / 2, y: lineY)
        }
    }
}

// MARK: - BIRGECanvasNodeMarker (internal helper)

/// A positioned node marker shown on the route canvas surface.
/// Not part of the public API — consumed by `BIRGERouteCanvas` only.
private struct BIRGECanvasNodeMarker: View {
    enum Position {
        case start, end
    }

    let isSelected: Bool
    let role: BIRGERouteCanvas.NodeRole
    let position: Position

    var body: some View {
        GeometryReader { geo in
            let pinSize: CGFloat = isSelected ? 18 : 13
            let x: CGFloat = position == .start ? 48 : geo.size.width - 42
            let y: CGFloat = geo.size.height * 0.51

            ZStack {
                // Outer glow ring
                if isSelected {
                    Circle()
                        .fill(pinColor.opacity(0.12))
                        .frame(width: pinSize + 16, height: pinSize + 16)
                }
                // White border ring
                Circle()
                    .fill(Color.white)
                    .frame(width: pinSize + 6, height: pinSize + 6)
                // Filled marker
                Circle()
                    .fill(pinColor)
                    .frame(width: pinSize, height: pinSize)
            }
            .position(x: x, y: y)
        }
    }

    private var pinColor: Color {
        guard isSelected || position == .end else {
            return BIRGEColors.textTertiary.opacity(0.35)
        }
        switch role {
        case .origin:
            return BIRGEColors.brandPrimary
        case .destination:
            return isSelected ? BIRGEColors.destinationPin : BIRGEColors.textTertiary.opacity(0.35)
        }
    }
}

// MARK: - Previews

#Preview("Origin Canvas") {
    VStack(spacing: BIRGELayout.l) {
        BIRGERouteCanvas(
            areaLabel: "Alatau City",
            title: "Where are you boarding?",
            subtitle: "Enter an address or choose a nearby node",
            role: .origin
        )
        .padding(.horizontal, BIRGELayout.s)

        BIRGERouteCanvas(
            areaLabel: "Esentai / Al-Farabi",
            title: "Where are you heading?",
            subtitle: "Enter your work or destination address",
            role: .destination
        )
        .padding(.horizontal, BIRGELayout.s)

        BIRGERouteCanvas(
            areaLabel: "Downtown",
            role: .origin
        )
        .padding(.horizontal, BIRGELayout.s)
    }
    .padding(.vertical, BIRGELayout.xl)
    .background(BIRGEColors.background)
}
