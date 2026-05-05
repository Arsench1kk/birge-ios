//
//  DriverOnlineControlSheet.swift
//  BIRGEDrive
//

import SwiftUI

struct DriverOnlineControlSheet: View {
    let earnings: DriverAppFeature.DriverEarnings
    let isLoadingTodayCorridors: Bool
    let todayCorridorsError: String?
    let todayCorridors: [DriverAppFeature.DriverDashboardCorridor]
    let endShift: () -> Void

    var body: some View {
        VStack(spacing: BIRGELayout.s) {
            todayCorridorsStrip

            HStack(spacing: BIRGELayout.s) {
                miniStat(label: "Поездок", value: "\(earnings.todayRides)")
                Divider().frame(height: 32)
                miniStat(label: "Сегодня", value: "\(earnings.todayTenge)₸")
                Divider().frame(height: 32)
                miniStat(label: "Неделя", value: "\(earnings.weekTenge)₸")
            }
            .padding(.horizontal, BIRGELayout.s)
            .padding(.vertical, BIRGELayout.xs)
            .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.04))

            VStack(spacing: BIRGELayout.xs) {
                Label("Алматы • активная зона", systemImage: "scope")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.success)
                    .lineLimit(1)

                BIRGESecondaryButton(title: "Завершить смену", action: endShift)
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.05), isInteractive: true)
    }

    @ViewBuilder
    private var todayCorridorsStrip: some View {
        if isLoadingTodayCorridors {
            BIRGELoadingState(title: "Загружаем коридоры", minHeight: 72)
        } else if let error = todayCorridorsError {
            BIRGEErrorState(title: "Коридоры недоступны", message: error)
        } else if let corridor = todayCorridors.first {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                HStack {
                    Label("Ближайший коридор", systemImage: "point.topleft.filled.down.to.point.bottomright.curvepath")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                    Spacer()
                    Text(corridor.departure)
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(corridor.name)
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textPrimary)
                        .lineLimit(1)
                    Text("\(corridor.originName) → \(corridor.destinationName)")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: BIRGELayout.xs) {
                    Label("\(corridor.seatsTotal) места", systemImage: "person.2.fill")
                    Label("\(corridor.estimatedEarnings)₸", systemImage: "tengesign.circle.fill")
                    Spacer()
                    Text("\(todayCorridors.count) активн.")
                }
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(label)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
    }
}
