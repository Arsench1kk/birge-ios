import SwiftUI

public struct BIRGETabItem: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let isSelected: Bool

    public init(
        id: String,
        title: String,
        systemImage: String,
        isSelected: Bool
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
    }
}

public struct BIRGETabBar: View {
    private let items: [BIRGETabItem]
    private let onSelect: (String) -> Void

    public init(
        items: [BIRGETabItem],
        onSelect: @escaping (String) -> Void
    ) {
        self.items = items
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    onSelect(item.id)
                } label: {
                    VStack(spacing: BIRGELayout.xxxs) {
                        Image(systemName: item.systemImage)
                            .font(BIRGEFonts.bodyMedium)

                        Text(item.title)
                            .font(BIRGEFonts.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .foregroundStyle(foreground(for: item))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: BIRGELayout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(item.isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, BIRGELayout.xs)
        .padding(.top, BIRGELayout.xs)
        .padding(.bottom, BIRGELayout.xxs)
        .background(BIRGEColors.passengerSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BIRGEColors.borderSubtle)
                .frame(height: 0.5)
        }
    }

    private func foreground(for item: BIRGETabItem) -> Color {
        item.isSelected ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary
    }
}

#Preview("Tab Bar") {
    VStack {
        Spacer()

        BIRGETabBar(
            items: [
                BIRGETabItem(
                    id: "home",
                    title: "Home",
                    systemImage: "house.fill",
                    isSelected: true
                ),
                BIRGETabItem(
                    id: "routes",
                    title: "Routes",
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                    isSelected: false
                ),
                BIRGETabItem(
                    id: "history",
                    title: "History",
                    systemImage: "clock.arrow.circlepath",
                    isSelected: false
                ),
                BIRGETabItem(
                    id: "profile",
                    title: "Profile",
                    systemImage: "person.crop.circle",
                    isSelected: false
                ),
            ],
            onSelect: { _ in }
        )
    }
    .background(BIRGEColors.passengerBackground)
}
