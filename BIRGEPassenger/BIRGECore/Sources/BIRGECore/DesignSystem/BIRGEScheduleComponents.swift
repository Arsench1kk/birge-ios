import SwiftUI

// MARK: - BIRGEWheelTimePicker

/// A native SwiftUI `.wheel` time picker styled to match the BIRGE polished
/// design system.
///
/// Matches the `ios-wheel-picker` pattern from P-03c-route-schedule.html:
/// - Two columns (hour 0–23, minute in 5-min steps) with a centred colon separator.
/// - Subtle glass-like selection band behind the centre row.
/// - Top/bottom fade mask (22 %–78 %) so off-centre rows softly dissolve.
/// - Row-height and font weights mirror the mockup: selected row is large and
///   dark (`textPrimary`), off-centre rows are lighter (`textTertiary`).
///
/// Usage:
/// ```swift
/// @State private var hour = 7
/// @State private var minute = 45
///
/// BIRGEWheelTimePicker(hour: $hour, minute: $minute)
/// ```
public struct BIRGEWheelTimePicker: View {

    // MARK: - Bindings

    @Binding public var hour: Int
    @Binding public var minute: Int

    // MARK: - Init

    public init(hour: Binding<Int>, minute: Binding<Int>) {
        self._hour = hour
        self._minute = minute
    }

    // MARK: - Constants

    /// Height of the visible picker drum. Matches `ios-wheel-picker` height (136 px).
    private let pickerHeight: CGFloat = 136
    /// Height of the centred selection highlight band. Matches `ios-wheel-band` (42 px).
    private let bandHeight: CGFloat = 42
    /// Width of each column. Narrower than UIPickerView default to keep columns close.
    private let columnWidth: CGFloat = 88
    /// Width of the colon separator. Matches `ios-wheel-separator` (16 px column).
    private let separatorWidth: CGFloat = 20

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .center) {
            // Glass-like selection band — sits behind the pickers
            selectionBand

            // Picker columns + separator
            HStack(spacing: 0) {
                hourColumn
                colonSeparator
                minuteColumn
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: pickerHeight)
        // Top / bottom fade mask, identical to the CSS mask-image on .ios-wheel-picker
        .mask(fadeMask)
        // Subtle top/bottom hairline borders
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BIRGEColors.borderSubtle)
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BIRGEColors.borderSubtle)
                .frame(height: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Time picker")
    }

    // MARK: - Sub-views

    /// The hour wheel column (0–23).
    private var hourColumn: some View {
        Picker("Hour", selection: $hour) {
            ForEach(0..<24, id: \.self) { value in
                Text(String(format: "%02d", value))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(
                        value == hour
                            ? BIRGEColors.textPrimary
                            : BIRGEColors.textTertiary.opacity(0.55)
                    )
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: columnWidth, height: pickerHeight)
        .clipped()
    }

    /// The minute wheel column (0, 5, 10, … 55).
    private var minuteColumn: some View {
        Picker("Minute", selection: $minute) {
            ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { value in
                Text(String(format: "%02d", value))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(
                        value == minute
                            ? BIRGEColors.textPrimary
                            : BIRGEColors.textTertiary.opacity(0.55)
                    )
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: columnWidth, height: pickerHeight)
        .clipped()
    }

    /// Centred colon glyph. Matches `ios-wheel-separator`: vertically centred,
    /// slightly offset (+1 pt downward) to align optically with the number baseline.
    private var colonSeparator: some View {
        Text(":")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(BIRGEColors.textPrimary)
            .frame(width: separatorWidth, height: bandHeight)
            .offset(y: 1)
            .accessibilityHidden(true)
    }

    /// Glass-like tinted band behind the selected row.
    /// Matches `.ios-wheel-band`: brandPrimary at 8 % opacity, radius 12,
    /// with a 1 pt inset accent stroke at 12 % opacity.
    private var selectionBand: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(BIRGEColors.brandPrimary.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BIRGEColors.brandPrimary.opacity(0.12), lineWidth: 1)
            )
            .frame(height: bandHeight)
            .padding(.horizontal, 4)
    }

    /// Gradient mask that fades rows above / below the selection zone.
    /// Matches CSS `mask-image: linear-gradient(transparent 0, #000 22%, #000 78%, transparent 100%)`.
    private var fadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .clear,  location: 0.00),
                .init(color: .black,  location: 0.22),
                .init(color: .black,  location: 0.78),
                .init(color: .clear,  location: 1.00),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - BIRGEWeekdayRail

/// A horizontal 7-column rail of weekday pills that can be toggled on/off.
///
/// Matches the `rm-week-rail` pattern from P-03c-route-schedule.html:
/// - 7 equal-width cells, each height 38 pt.
/// - Active cells show `brandPrimary` text and a `brandPrimary` bottom border.
/// - Inactive cells show `textTertiary` text with a `borderSubtle` bottom border.
///
/// Usage:
/// ```swift
/// @State private var selected: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri"]
///
/// BIRGEWeekdayRail(
///     weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
///     selectedWeekdays: selected
/// ) { day in
///     if selected.contains(day) { selected.remove(day) } else { selected.insert(day) }
/// }
/// ```
public struct BIRGEWeekdayRail: View {

    // MARK: - Properties

    /// All weekday tokens, in display order. Typically 7 items.
    public let weekdays: [String]
    /// The currently active weekday tokens.
    public let selectedWeekdays: Set<String>
    /// Called when any day pill is tapped.
    public let onToggle: (String) -> Void

    // MARK: - Init

    public init(
        weekdays: [String],
        selectedWeekdays: Set<String>,
        onToggle: @escaping (String) -> Void
    ) {
        self.weekdays = weekdays
        self.selectedWeekdays = selectedWeekdays
        self.onToggle = onToggle
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(weekdays, id: \.self) { day in
                dayCell(for: day)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekday selector")
    }

    // MARK: - Helpers

    private func dayCell(for day: String) -> some View {
        let isActive = selectedWeekdays.contains(day)

        return Button {
            onToggle(day)
        } label: {
            Text(day)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(
                    isActive ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isActive ? BIRGEColors.brandPrimary : BIRGEColors.borderSubtle)
                        .frame(height: isActive ? 2 : 1)
                }
        }
        .buttonStyle(BIRGEPressableButtonStyle())
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActive)
        .accessibilityLabel(day)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
        .accessibilityHint(isActive ? "Tap to deselect" : "Tap to select")
    }
}

// MARK: - BIRGEFlexSegments

/// An iOS-style segmented control for discrete flexibility/window options.
///
/// Matches the `ios-flex-segments` pattern from P-03c-route-schedule.html:
/// - Options rendered in equal-width slots inside a pill-shaped track.
/// - Active segment: white background, `brandPrimary` text, subtle shadow.
/// - Inactive segments: `textTertiary` text, transparent background.
///
/// Usage:
/// ```swift
/// @State private var flexMinutes = 30
///
/// BIRGEFlexSegments(options: [15, 30, 45], selected: flexMinutes) { value in
///     flexMinutes = value
/// }
/// ```
public struct BIRGEFlexSegments: View {

    // MARK: - Properties

    /// The available option values (e.g. `[15, 30, 45]`).
    public let options: [Int]
    /// The currently selected value. Must be one of `options`.
    public let selected: Int
    /// Called when the user taps a segment.
    public let onSelect: (Int) -> Void

    // MARK: - Init

    public init(
        options: [Int],
        selected: Int,
        onSelect: @escaping (Int) -> Void
    ) {
        self.options = options
        self.selected = selected
        self.onSelect = onSelect
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { value in
                segmentButton(for: value)
            }
        }
        .padding(4)
        // Track background: slightly muted surface with an inset border.
        // Matches `ios-flex-segments` background/box-shadow.
        .background(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .fill(BIRGEColors.surfaceGrouped)
                .overlay(
                    RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                        .stroke(BIRGEColors.borderSubtle.opacity(0.78), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Flexibility window selector")
    }

    // MARK: - Helpers

    @ViewBuilder
    private func segmentButton(for value: Int) -> some View {
        let isActive = value == selected

        Button {
            onSelect(value)
        } label: {
            Text("±\(value) min")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(
                    isActive ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    Group {
                        if isActive {
                            RoundedRectangle(cornerRadius: BIRGELayout.radiusS)
                                .fill(BIRGEColors.surfacePrimary)
                                .shadow(
                                    color: Color(red: 0.01, green: 0.09, blue: 0.22).opacity(0.08),
                                    radius: 4.5, y: 2
                                )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
        }
        .buttonStyle(BIRGEPressableButtonStyle())
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isActive)
        .accessibilityLabel("±\(value) minutes")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

// MARK: - Previews

#Preview("Wheel Time Picker") {
    @Previewable @State var hour = 7
    @Previewable @State var minute = 45

    VStack(spacing: BIRGELayout.m) {
        HStack {
            Text("Departure time")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
            Spacer()
            Text(String(format: "%02d:%02d", hour, minute))
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(BIRGEColors.textPrimary)
        }
        .padding(.horizontal, BIRGELayout.s)

        BIRGEWheelTimePicker(hour: $hour, minute: $minute)
    }
    .padding(.vertical, BIRGELayout.xl)
    .background(BIRGEColors.background)
}

#Preview("Weekday Rail") {
    @Previewable @State var selected: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri"]

    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    VStack(spacing: BIRGELayout.s) {
        BIRGEWeekdayRail(
            weekdays: weekdays,
            selectedWeekdays: selected
        ) { day in
            if selected.contains(day) {
                selected.remove(day)
            } else {
                selected.insert(day)
            }
        }

        Text("Selected: \(selected.sorted().joined(separator: ", "))")
            .font(BIRGEFonts.caption)
            .foregroundStyle(BIRGEColors.textSecondary)
    }
    .padding(BIRGELayout.m)
    .background(BIRGEColors.background)
}

#Preview("Flex Segments") {
    @Previewable @State var flexMinutes = 30

    VStack(spacing: BIRGELayout.xs) {
        HStack {
            Text("Flexibility")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
            Spacer()
            Text("Window: ±\(flexMinutes) min")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(BIRGEColors.textPrimary)
        }

        BIRGEFlexSegments(options: [15, 30, 45], selected: flexMinutes) { value in
            flexMinutes = value
        }
    }
    .padding(BIRGELayout.m)
    .background(BIRGEColors.background)
}

#Preview("Full Schedule Block") {
    @Previewable @State var hour = 7
    @Previewable @State var minute = 45
    @Previewable @State var selected: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    @Previewable @State var flexMinutes = 30

    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    ScrollView {
        VStack(alignment: .leading, spacing: BIRGELayout.m) {
            Text("Schedule")
                .font(BIRGEFonts.title)
                .foregroundStyle(BIRGEColors.textPrimary)

            Text("When do you usually commute?")
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)

            BIRGEWeekdayRail(
                weekdays: weekdays,
                selectedWeekdays: selected
            ) { day in
                if selected.contains(day) {
                    selected.remove(day)
                } else {
                    selected.insert(day)
                }
            }

            VStack(spacing: BIRGELayout.s) {
                HStack {
                    Text("Departure time")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textSecondary)
                    Spacer()
                    Text(String(format: "%02d:%02d", hour, minute))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(BIRGEColors.textPrimary)
                }

                BIRGEWheelTimePicker(hour: $hour, minute: $minute)

                VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                    HStack {
                        Text("Flexibility")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.textSecondary)
                        Spacer()
                        Text("Window: ±\(flexMinutes) min")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(BIRGEColors.textPrimary)
                    }

                    BIRGEFlexSegments(options: [15, 30, 45], selected: flexMinutes) { value in
                        flexMinutes = value
                    }
                }
                .padding(BIRGELayout.s)
                .background(BIRGEColors.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
                .overlay(
                    RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                        .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
                )
            }
        }
        .padding(BIRGELayout.m)
    }
    .background(BIRGEColors.background)
}
