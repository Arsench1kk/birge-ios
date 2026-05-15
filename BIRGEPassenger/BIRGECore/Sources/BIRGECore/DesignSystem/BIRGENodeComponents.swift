import SwiftUI

// MARK: - BIRGENodePin

/// A circular map-pin marker that can be shown in selected or unselected state.
///
/// Mirrors the `.rm-node-pin` / `.rm-node-pin.selected` CSS pattern from the
/// passenger-polished mockups (P-03a / P-03b).
///
/// Usage:
/// ```swift
/// BIRGENodePin(isSelected: true, role: .origin, label: "Main entrance")
/// BIRGENodePin(isSelected: false, role: .destination, label: "Parking B")
/// ```
public struct BIRGENodePin: View {

    // MARK: - Node Role

    /// Whether the pin belongs to the origin (pick-up) or destination (drop-off) flow.
    public enum NodeRole {
        case origin
        case destination
    }

    // MARK: - Stored Properties

    public let isSelected: Bool
    public let role: NodeRole
    /// Accessibility / VoiceOver label for the pin.
    public let label: String

    // MARK: - Init

    public init(
        isSelected: Bool,
        role: NodeRole = .origin,
        label: String
    ) {
        self.isSelected = isSelected
        self.role = role
        self.label = label
    }

    // MARK: - Sizing constants

    private var outerSize: CGFloat { isSelected ? 18 : 13 }
    private var glowRadius: CGFloat { 8 }

    private var pinColor: Color {
        switch (isSelected, role) {
        case (true, .origin):      return BIRGEColors.brandPrimary
        case (true, .destination): return BIRGEColors.destinationPin
        case (false, _):           return BIRGEColors.textTertiary.opacity(0.35)
        }
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Outer glow ring — only shown when selected
            if isSelected {
                Circle()
                    .fill(pinColor.opacity(0.12))
                    .frame(width: outerSize + glowRadius * 2, height: outerSize + glowRadius * 2)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }

            // White border ring
            Circle()
                .fill(Color.white)
                .frame(width: outerSize + 6, height: outerSize + 6)
                .shadow(color: Color.black.opacity(0.06), radius: 3, y: 1)

            // Filled dot
            Circle()
                .fill(pinColor)
                .frame(width: outerSize, height: outerSize)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - BIRGENodeSelectorRow

/// A list row representing a commute node (pickup / dropoff stop).
/// Displays a pin indicator, a title, an optional detail string, and an
/// optional trailing metric (e.g. walking time).
///
/// Mirrors `.rm-node-row` / `.rm-node-row.selected` from the polished mockups.
///
/// Usage:
/// ```swift
/// BIRGENodeSelectorRow(
///     title: "Main ЖК entrance",
///     detail: "~2 min walk from Alatau City",
///     trailingMetric: "2 min",
///     isSelected: true,
///     role: .origin
/// )
/// ```
public struct BIRGENodeSelectorRow: View {

    // MARK: - Stored Properties

    /// Primary bold label (node name).
    public let title: String
    /// Secondary muted detail (e.g. walking time hint).
    public let detail: String?
    /// Optional right-aligned metric label (e.g. "4 min").
    public let trailingMetric: String?
    public let isSelected: Bool
    /// Controls pin colour; defaults to `.origin`.
    public let role: BIRGENodePin.NodeRole

    // MARK: - Init

    public init(
        title: String,
        detail: String? = nil,
        trailingMetric: String? = nil,
        isSelected: Bool = false,
        role: BIRGENodePin.NodeRole = .origin
    ) {
        self.title = title
        self.detail = detail
        self.trailingMetric = trailingMetric
        self.isSelected = isSelected
        self.role = role
    }

    // MARK: - Body

    public var body: some View {
        HStack(alignment: .center, spacing: BIRGELayout.xs) {
            // Pin dot indicator
            pinDot

            // Text stack
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(title)
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(2)

                if let detail {
                    Text(detail)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Trailing area: metric label or checkmark
            trailingView
        }
        .padding(.vertical, BIRGELayout.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Sub-views

    /// Small coloured dot that turns brand-primary when selected.
    private var pinDot: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(pinColor.opacity(0.12))
                    .frame(width: 18, height: 18)
            }
            Circle()
                .fill(isSelected ? pinColor : BIRGEColors.textTertiary.opacity(0.30))
                .frame(width: 10, height: 10)
        }
        .frame(width: 18, height: 18)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isSelected)
    }

    @ViewBuilder
    private var trailingView: some View {
        if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(pinColor)
                .transition(.scale.combined(with: .opacity))
        } else if let metric = trailingMetric {
            Text(metric)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textTertiary)
        } else {
            // Invisible placeholder keeps row height consistent
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .hidden()
        }
    }

    // MARK: - Helpers

    private var pinColor: Color {
        switch role {
        case .origin:      return BIRGEColors.brandPrimary
        case .destination: return BIRGEColors.destinationPin
        }
    }

    private var accessibilityDescription: String {
        var parts = [title]
        if let detail { parts.append(detail) }
        if let metric = trailingMetric { parts.append(metric) }
        if isSelected { parts.append("Selected") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - BIRGENodeSelectorList

/// A convenience wrapper that renders a bordered, grouped list of
/// `BIRGENodeSelectorRow` items separated by `BIRGEColors.borderSubtle` dividers.
///
/// Usage:
/// ```swift
/// BIRGENodeSelectorList(
///     nodes: mockNodes,
///     selectedID: selectedID,
///     role: .origin
/// ) { node in
///     selectedID = node.id
/// }
/// ```
public struct BIRGENodeSelectorList: View {

    public let nodes: [MockCommuteNode]
    public let selectedID: MockCommuteNode.ID?
    public let role: BIRGENodePin.NodeRole
    public let onSelect: (MockCommuteNode) -> Void

    public init(
        nodes: [MockCommuteNode],
        selectedID: MockCommuteNode.ID?,
        role: BIRGENodePin.NodeRole = .origin,
        onSelect: @escaping (MockCommuteNode) -> Void
    ) {
        self.nodes = nodes
        self.selectedID = selectedID
        self.role = role
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                Button {
                    onSelect(node)
                } label: {
                    BIRGENodeSelectorRow(
                        title: node.title,
                        detail: node.subtitle,
                        trailingMetric: node.walkingMinutes > 0
                            ? "\(node.walkingMinutes) min"
                            : nil,
                        isSelected: node.id == selectedID,
                        role: role
                    )
                    .padding(.horizontal, BIRGELayout.s)
                }
                .buttonStyle(BIRGEPressableButtonStyle())

                if index < nodes.count - 1 {
                    Divider()
                        .background(BIRGEColors.borderSubtle)
                        .padding(.leading, BIRGELayout.s + 18 + BIRGELayout.xs)
                }
            }
        }
        .background(BIRGEColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview("Node Pin States") {
    HStack(spacing: BIRGELayout.l) {
        VStack(spacing: BIRGELayout.m) {
            Text("Origin").font(BIRGEFonts.captionBold).foregroundStyle(BIRGEColors.textSecondary)
            BIRGENodePin(isSelected: true, role: .origin, label: "Main entrance — selected")
            BIRGENodePin(isSelected: false, role: .origin, label: "Parking B — unselected")
        }
        VStack(spacing: BIRGELayout.m) {
            Text("Destination").font(BIRGEFonts.captionBold).foregroundStyle(BIRGEColors.textSecondary)
            BIRGENodePin(isSelected: true, role: .destination, label: "South entrance — selected")
            BIRGENodePin(isSelected: false, role: .destination, label: "Parking P2 — unselected")
        }
    }
    .padding(BIRGELayout.xl)
    .background(BIRGEColors.routeCanvasBackground)
}

#Preview("Node Selector Row") {
    VStack(spacing: 0) {
        BIRGENodeSelectorRow(
            title: "Main ЖК Entrance",
            detail: "~2 min walk from Alatau City",
            trailingMetric: "2 min",
            isSelected: true,
            role: .origin
        )
        .padding(.horizontal, BIRGELayout.s)
        Divider().padding(.leading, BIRGELayout.s)
        BIRGENodeSelectorRow(
            title: "Parking at Block B",
            detail: "~4 min walk",
            trailingMetric: "4 min",
            isSelected: false,
            role: .origin
        )
        .padding(.horizontal, BIRGELayout.s)
        Divider().padding(.leading, BIRGELayout.s)
        BIRGENodeSelectorRow(
            title: "Saina Street",
            detail: "~6 min walk",
            isSelected: false,
            role: .origin
        )
        .padding(.horizontal, BIRGELayout.s)
    }
    .background(BIRGEColors.surfacePrimary)
    .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
    .padding(BIRGELayout.s)
    .background(BIRGEColors.background)
}

#Preview("Node Selector List — Origin") {
    @Previewable @State var selectedID: MockCommuteNode.ID? = MockCommuteNode.previewNodes[0].id

    VStack(alignment: .leading, spacing: BIRGELayout.xs) {
        Text("Nearest boarding points")
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(BIRGEColors.textSecondary)
            .padding(.horizontal, BIRGELayout.s)

        BIRGENodeSelectorList(
            nodes: MockCommuteNode.previewNodes,
            selectedID: selectedID,
            role: .origin
        ) { node in
            selectedID = node.id
        }
    }
    .padding(BIRGELayout.s)
    .background(BIRGEColors.background)
}

#Preview("Node Selector List — Destination") {
    @Previewable @State var selectedID: MockCommuteNode.ID? = MockCommuteNode.previewDestinationNodes[0].id

    VStack(alignment: .leading, spacing: BIRGELayout.xs) {
        Text("Nearest drop-off points")
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(BIRGEColors.textSecondary)
            .padding(.horizontal, BIRGELayout.s)

        BIRGENodeSelectorList(
            nodes: MockCommuteNode.previewDestinationNodes,
            selectedID: selectedID,
            role: .destination
        ) { node in
            selectedID = node.id
        }
    }
    .padding(BIRGELayout.s)
    .background(BIRGEColors.background)
}

// MARK: - Preview Mock Fixtures (preview-only extension)

private extension MockCommuteNode {
    static let previewNodes: [MockCommuteNode] = [
        MockCommuteNode(
            id: UUID(),
            title: "Main ЖК Entrance",
            subtitle: "~2 min walk from Alatau City",
            coordinate: LatLng(latitude: 43.36, longitude: 77.01),
            walkingMinutes: 2
        ),
        MockCommuteNode(
            id: UUID(),
            title: "Parking at Block B",
            subtitle: "~4 min walk",
            coordinate: LatLng(latitude: 43.361, longitude: 77.012),
            walkingMinutes: 4
        ),
        MockCommuteNode(
            id: UUID(),
            title: "Saina Street",
            subtitle: "~6 min walk",
            coordinate: LatLng(latitude: 43.362, longitude: 77.013),
            walkingMinutes: 6
        ),
    ]

    static let previewDestinationNodes: [MockCommuteNode] = [
        MockCommuteNode(
            id: UUID(),
            title: "Esentai Park, South Entrance",
            subtitle: "3–5 min walk to offices",
            coordinate: LatLng(latitude: 43.21, longitude: 76.93),
            walkingMinutes: 3
        ),
        MockCommuteNode(
            id: UUID(),
            title: "Esentai Mall, Parking P2",
            subtitle: "Handy after meetings",
            coordinate: LatLng(latitude: 43.211, longitude: 76.931),
            walkingMinutes: 5
        ),
        MockCommuteNode(
            id: UUID(),
            title: "Al-Farabi Business Centre",
            subtitle: "Closer to the boulevard",
            coordinate: LatLng(latitude: 43.212, longitude: 76.932),
            walkingMinutes: 7
        ),
    ]
}
