//
//  DriverCompletedRideSheet.swift
//  BIRGEDrive
//

import SwiftUI

struct DriverCompletedRideSheet: View {
    let summary: DriverAppFeature.CompletedRideSummary
    let findNextRide: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: BIRGELayout.s) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(BIRGEColors.success)

            VStack(spacing: BIRGELayout.xxxs) {
                Text("Поездка завершена")
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("Отличная работа")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            VStack(spacing: BIRGELayout.s) {
                Text("\(summary.fare)₸")
                    .font(BIRGEFonts.heroNumber)
                    .foregroundStyle(BIRGEColors.success)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BIRGELayout.xs), count: 3), spacing: BIRGELayout.xs) {
                    completionStat(value: "\(summary.durationMinutes) мин", label: "Время")
                    completionStat(value: String(format: "%.1f км", summary.distanceKm), label: "Дистанция")
                    completionStat(value: "\(summary.passengers) чел", label: "Пассажиры")
                }
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.04))

            Label("\(summary.todayTenge)₸ · \(summary.todayRides) поездок сегодня", systemImage: "chart.line.uptrend.xyaxis")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .padding(.horizontal, BIRGELayout.s)
                .padding(.vertical, BIRGELayout.xs)
                .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.08))

            VStack(spacing: BIRGELayout.xs) {
                BIRGEPrimaryButton(title: "Следующая поездка", action: findNextRide)
                BIRGESecondaryButton(title: "Готово", action: dismiss)
            }
        }
        .padding(BIRGELayout.m)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.06), isInteractive: true)
    }

    private func completionStat(value: String, label: String) -> some View {
        VStack(spacing: BIRGELayout.xxxs) {
            Text(value)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(label)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
    }
}
