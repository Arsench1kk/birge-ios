import SwiftUI

// MARK: - BIRGERouteReviewTicket

/// A polished, fully reusable route-review card for the BIRGE passenger design system.
///
/// Displays a `MockRouteDraft` in two stacked sections that match the
/// `review-route-panel` + `review-schedule-strip` CSS pattern from
/// P-03d-route-review.html:
///
/// 1. **Stop panel** — origin and destination rows separated by a vertical
///    connector line (start dot → dashed connector → end dot). If a pickup /
///    dropoff node is available in the draft, its title is appended as a
///    secondary line below the address.
/// 2. **Schedule strip** — three bordered metric cells:
///    Days · Window · Departure.
///
/// Usage:
/// ```swift
/// BIRGERouteReviewTicket(draft: BIRGEProductFixtures.Passenger.draftRoute)
/// ```
///
/// - Note: This component is independent of TCA and reads only from
///   `MockRouteDraft`. It uses BIRGE design tokens exclusively.
public struct BIRGERouteReviewTicket: View {

    // MARK: - Stored properties

    public let draft: MockRouteDraft

    // MARK: - Init

    public init(draft: MockRouteDraft) {
        self.draft = draft
    }

    // MARK: - Derived display values

    /// Resolved pickup node title (from `suggestedPickupNodes` + `selectedPickupNodeID`).
    private var pickupNodeTitle: String? {
        guard let id = draft.selectedPickupNodeID else { return nil }
        return draft.suggestedPickupNodes.first { $0.id == id }?.title
    }

    /// Resolved dropoff node title.
    private var dropoffNodeTitle: String? {
        guard let id = draft.selectedDropoffNodeID else { return nil }
        return draft.suggestedDropoffNodes.first { $0.id == id }?.title
    }

    /// Compact weekday summary: consecutive runs collapsed to "Mon–Fri" style.
    private var weekdaysSummary: String {
        let days = draft.schedule.weekdays
        guard !days.isEmpty else { return "—" }
        if days.map({ $0.lowercased() }) == ["mon", "tue", "wed", "thu", "fri"] {
            return "Пн–Пт"
        }
        return days.map(displayWeekday).joined(separator: "·")
    }

    /// Departure window formatted as "HH:mm–HH:mm".
    private var windowSummary: String {
        let start = draft.schedule.departureWindowStart
        let end   = draft.schedule.departureWindowEnd
        guard !start.isEmpty, !end.isEmpty else { return "—" }
        return "\(start)–\(end)"
    }

    /// Preferred departure time — the window start (same source as the scheduler).
    private var departureSummary: String {
        let start = draft.schedule.departureWindowStart
        return start.isEmpty ? "—" : start
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            routePanel
            scheduleStrip
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Route review — \(draft.displayName)")
    }

    // MARK: - Route panel

    private var routePanel: some View {
        stopPanel
            .padding(.horizontal, 15)
            .padding(.vertical, BIRGELayout.s)
            .background(routePanelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(BIRGEColors.brandPrimary.opacity(0.18), lineWidth: 1)
            )
            .shadow(
                color: BIRGEColors.textPrimary.opacity(0.07),
                radius: 14,
                y: 6
            )
    }

    /// Subtle brand-tinted gradient matching `review-route-panel`.
    private var routePanelBackground: some View {
        LinearGradient(
            colors: [
                BIRGEColors.brandPrimary.opacity(0.06),
                BIRGEColors.surfacePrimary
            ],
            startPoint: .topLeading,
            endPoint: UnitPoint(x: 0.7, y: 1)
        )
    }

    // MARK: - Stop panel

    /// Two-column layout: left = vertical connector line, right = stop text.
    /// Matches `.review-route-line` grid (`24 px icon column` + `1fr text`).
    private var stopPanel: some View {
        HStack(alignment: .top, spacing: 12) {
            connectorLine
            stopTextColumn
        }
    }

    /// The vertical line + two node markers replicating `.review-route-line`:
    /// - Top: filled `brandPrimary` circle (origin)
    /// - Middle: thin dashed or faded connector bar
    /// - Bottom: filled `textPrimary` circle (destination)
    private var connectorLine: some View {
        VStack(spacing: 0) {
            // Origin dot
            Circle()
                .fill(BIRGEColors.brandPrimary)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: BIRGEColors.brandPrimary.opacity(0.25), radius: 3, y: 1)

            // Connector bar — faded brand colour, matches `review-route-line i`
            Rectangle()
                .fill(BIRGEColors.brandPrimary.opacity(0.30))
                .frame(width: 2)
                .frame(minHeight: 36)
                .clipShape(Capsule())

            // Destination dot
            Circle()
                .fill(BIRGEColors.textPrimary)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: BIRGEColors.textPrimary.opacity(0.15), radius: 3, y: 1)
        }
        .frame(width: 18)
        .padding(.top, 2)
    }

    private var stopTextColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Origin stop
            stopCell(
                metaLabel: "Посадка",
                primaryText: draft.originAddress,
                nodeText: pickupNodeTitle
            )
            .padding(.bottom, BIRGELayout.xs)

            // Destination stop
            stopCell(
                metaLabel: "Высадка",
                primaryText: draft.destinationAddress,
                nodeText: dropoffNodeTitle
            )
        }
    }

    /// A single stop row: meta label + bold address + optional node subtitle.
    private func stopCell(
        metaLabel: String,
        primaryText: String,
        nodeText: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(metaLabel)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textTertiary)
                .accessibilityHidden(true)

            Text(primaryText)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)

            if let nodeText {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BIRGEColors.brandPrimary)
                    Text(nodeText)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metaLabel): \(primaryText)\(nodeText.map { ", node: \($0)" } ?? "")")
    }

    // MARK: - Schedule strip

    /// Three bordered cells in a horizontal strip.
    /// Matches `.review-schedule-strip` grid: `1fr  1.25fr  1fr` with left borders.
    private var scheduleStrip: some View {
        HStack(spacing: 0) {
            scheduleCell(label: "Дни",   value: weekdaysSummary,  isFirst: true)
            scheduleCell(label: "Окно",  value: windowSummary,    isFirst: false)
            scheduleCell(label: "Выезд", value: departureSummary, isFirst: false)
        }
        .frame(maxWidth: .infinity)
        .background(BIRGEColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
        )
    }

    /// A single schedule metric cell.
    private func scheduleCell(label: String, value: String, isFirst: Bool) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(label)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textTertiary)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .monospacedDigit()
        }
        .padding(.horizontal, BIRGELayout.xs)
        .padding(.vertical, BIRGELayout.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            if !isFirst {
                Rectangle()
                    .fill(BIRGEColors.borderSubtle)
                    .frame(width: 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func displayWeekday(_ weekday: String) -> String {
        switch weekday.lowercased() {
        case "mon": return "Пн"
        case "tue": return "Вт"
        case "wed": return "Ср"
        case "thu": return "Чт"
        case "fri": return "Пт"
        case "sat": return "Сб"
        case "sun": return "Вс"
        default: return String(weekday.prefix(2)).capitalized
        }
    }
}

// MARK: - Previews

#Preview("Full draft — nodes selected") {
    ScrollView {
        VStack(spacing: BIRGELayout.l) {
            BIRGERouteReviewTicket(draft: .previewFull)
                .padding(.horizontal, BIRGELayout.m)

            BIRGERouteReviewTicket(draft: .previewNoNodes)
                .padding(.horizontal, BIRGELayout.m)

            BIRGERouteReviewTicket(draft: .previewLongNames)
                .padding(.horizontal, BIRGELayout.m)
        }
        .padding(.vertical, BIRGELayout.xl)
    }
    .background(BIRGEColors.background)
}

#Preview("Minimal — no nodes") {
    BIRGERouteReviewTicket(draft: .previewNoNodes)
        .padding(BIRGELayout.m)
        .background(BIRGEColors.background)
}

#Preview("Dark background") {
    BIRGERouteReviewTicket(draft: .previewFull)
        .padding(BIRGELayout.m)
        .background(Color(white: 0.08))
}

// MARK: - Preview mock data (file-private — never shipped to production)

private extension MockRouteDraft {

    /// Mirrors `BIRGEProductFixtures.Passenger.draftRoute` shape without importing the fixture enum.
    static let previewFull = MockRouteDraft(
        id: UUID(),
        displayName: "Alatau City → Esentai / Al-Farabi",
        originAddress: "Alatau City",
        destinationAddress: "Esentai / Al-Farabi",
        suggestedPickupNodes: [
            MockCommuteNode(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
                title: "Алатау City, северный вход",
                subtitle: "4 min walk",
                coordinate: LatLng(latitude: 43.2632, longitude: 76.8217),
                walkingMinutes: 4
            )
        ],
        suggestedDropoffNodes: [
            MockCommuteNode(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
                title: "Esentai Park, South Entrance",
                subtitle: "3 min walk",
                coordinate: LatLng(latitude: 43.2189, longitude: 76.9275),
                walkingMinutes: 3
            )
        ],
        selectedPickupNodeID: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
        selectedDropoffNodeID: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
        schedule: MockRouteSchedule(
            weekdays: ["mon", "tue", "wed", "thu", "fri"],
            departureWindowStart: "07:15",
            departureWindowEnd: "08:30"
        )
    )

    /// No nodes selected — tests graceful degradation of node subtitles.
    static let previewNoNodes = MockRouteDraft(
        id: UUID(),
        displayName: "Home → Office",
        originAddress: "Residential District A",
        destinationAddress: "Business Park B",
        suggestedPickupNodes: [],
        suggestedDropoffNodes: [],
        selectedPickupNodeID: nil,
        selectedDropoffNodeID: nil,
        schedule: MockRouteSchedule(
            weekdays: ["mon", "wed", "fri"],
            departureWindowStart: "08:00",
            departureWindowEnd: "09:00"
        )
    )

    /// Long address strings — tests text wrapping and `minimumScaleFactor`.
    static let previewLongNames = MockRouteDraft(
        id: UUID(),
        displayName: "Nursultan Nazarbayev International Airport → Esentai Mall Business District",
        originAddress: "Nursultan Nazarbayev International Airport",
        destinationAddress: "Esentai Mall Business District, Almaty",
        suggestedPickupNodes: [
            MockCommuteNode(
                id: UUID(),
                title: "Terminal 1, Departure Hall North Wing",
                subtitle: "6 min walk",
                coordinate: LatLng(latitude: 43.35, longitude: 77.04),
                walkingMinutes: 6
            )
        ],
        suggestedDropoffNodes: [],
        selectedPickupNodeID: nil,
        selectedDropoffNodeID: nil,
        schedule: MockRouteSchedule(
            weekdays: ["mon", "tue", "wed", "thu", "fri", "sat"],
            departureWindowStart: "06:30",
            departureWindowEnd: "07:45"
        )
    )
}
