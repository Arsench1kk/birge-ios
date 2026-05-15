//
//  RouteScheduleStepView.swift
//  BIRGEPassenger
//
//  Matches P-03c-route-schedule.html:
//  "Расписание" — weekday rail, wheel time picker, flex segments, insight line.
//  Step 3 of 5 in the first-route-entry flow.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

// MARK: - RouteScheduleStepView

struct RouteScheduleStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(
                title: "Расписание",
                subtitle: "Когда ездите обычно?"
            )

            // Weekday rail — Пн through Вс
            BIRGEWeekdayRail(
                weekdays: store.availableWeekdays.map(displayName),
                selectedWeekdays: Set(store.selectedWeekdays.map(displayName)),
                onToggle: { label in
                    // Map display label back to the raw token the reducer expects
                    if let raw = store.availableWeekdays.first(where: { displayName($0) == label }) {
                        store.send(.weekdayToggled(raw))
                    }
                }
            )
            .accessibilityIdentifier("passenger_schedule_weekday_rail")

            // Time picker block
            VStack(spacing: BIRGELayout.s) {
                // Label row: "Время выезда" + current time value
                HStack {
                    Text("Время выезда")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textSecondary)
                    Spacer()
                    Text(store.departureTime.isEmpty ? "—" : store.departureTime)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(BIRGEColors.textPrimary)
                        .accessibilityIdentifier("passenger_schedule_departure_label")
                }

                // Wheel picker — bindings derive hour/minute from the "HH:mm" string
                BIRGEWheelTimePicker(
                    hour: hourBinding,
                    minute: minuteBinding
                )
                .accessibilityIdentifier("passenger_schedule_departure_time")

                // Flexibility block
                VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                    HStack {
                        Text("Гибкость")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.textSecondary)
                        Spacer()
                        Text("Окно: \(windowText)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(BIRGEColors.textPrimary)
                            .accessibilityIdentifier("passenger_schedule_window_label")
                    }

                    BIRGEFlexSegments(
                        options: [15, 30, 45],
                        selected: store.flexibilityMinutes
                    ) { value in
                        store.send(.flexibilityMinutesChanged(value))
                    }
                    .accessibilityIdentifier("passenger_schedule_flex_segments")
                }
                .padding(BIRGELayout.s)
                .background(BIRGEColors.passengerSurface)
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
                .overlay(
                    RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                        .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
                )
            }

            InsightLine(text: "Чем шире окно, тем проще подобрать поездку.")
        }
        .accessibilityIdentifier("passenger_route_schedule")
    }

    // MARK: - Bindings

    /// Derives the hour integer from `store.departureTime` ("HH:mm").
    private var hourBinding: Binding<Int> {
        Binding(
            get: { hourValue },
            set: { store.send(.departureHourChanged($0)) }
        )
    }

    /// Derives the minute integer (snapped to 5-min steps) from `store.departureTime`.
    private var minuteBinding: Binding<Int> {
        Binding(
            get: { minuteValue },
            set: { store.send(.departureMinuteChanged($0)) }
        )
    }

    // MARK: - Computed helpers

    private var hourValue: Int {
        let parts = store.departureTime.split(separator: ":").compactMap { Int($0) }
        return parts.first.map { max(0, min(23, $0)) } ?? 7
    }

    private var minuteValue: Int {
        let parts = store.departureTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count > 1 else { return 45 }
        let raw = max(0, min(59, parts[1]))
        return (raw / 5) * 5
    }

    private var windowText: String {
        guard !store.departureTime.isEmpty else { return "—" }
        return "\(store.departureTime)–\(store.departureWindowEnd)"
    }

    /// Converts a raw weekday token (e.g. "mon") to a 2-letter display label ("Пн").
    private func displayName(_ weekday: String) -> String {
        switch weekday.lowercased() {
        case "mon": return "Пн"
        case "tue": return "Вт"
        case "wed": return "Ср"
        case "thu": return "Чт"
        case "fri": return "Пт"
        case "sat": return "Сб"
        case "sun": return "Вс"
        default:    return String(weekday.prefix(2)).uppercased()
        }
    }
}

// MARK: - Previews

#Preview("Schedule — empty") {
    ScrollView {
        RouteScheduleStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .schedule
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Schedule — morning preset") {
    ScrollView {
        RouteScheduleStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .schedule,
                selectedWeekdays: Set(BIRGEProductFixtures.Passenger.morningSchedule.weekdays),
                departureTime: BIRGEProductFixtures.Passenger.morningSchedule.departureWindowStart,
                flexibilityMinutes: 30
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}
