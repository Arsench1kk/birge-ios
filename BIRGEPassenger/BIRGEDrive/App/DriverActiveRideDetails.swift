//
//  DriverActiveRideDetails.swift
//  BIRGEDrive
//

import SwiftUI

struct DriverNavigationPanel: View {
    let ride: DriverAppFeature.DriverActiveRide

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack {
                Label("Навигация активна", systemImage: "location.north.line.fill")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(DriverRideFormatting.statusColor(for: ride.status))
                Spacer()
                Text(DriverRideFormatting.routePhaseText(for: ride.status))
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            HStack(alignment: .top, spacing: BIRGELayout.xs) {
                Image(systemName: DriverRideFormatting.maneuverSymbol(for: ride.status))
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DriverRideFormatting.statusColor(for: ride.status)))

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(DriverRideFormatting.nextManeuverText(for: ride))
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textPrimary)
                        .lineLimit(2)
                    Text(DriverRideFormatting.routeGuidanceDetail(for: ride))
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: BIRGELayout.xs) {
                DriverGuidanceChip(icon: "clock.fill", value: "\(ride.etaMinutes) мин")
                DriverGuidanceChip(icon: "speedometer", value: "42 км/ч")
                DriverGuidanceChip(icon: "shield.lefthalf.filled", value: "спокойно")
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(
            .card,
            tint: DriverRideFormatting.statusColor(for: ride.status).opacity(0.045),
            isInteractive: true
        )
    }
}

struct DriverRouteProgress: View {
    let status: DriverAppFeature.DriverActiveRide.RideStatus

    var body: some View {
        VStack(spacing: BIRGELayout.xxs) {
            HStack {
                Text(DriverRideFormatting.progressLabel(for: status))
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Spacer()
                Text(DriverRideFormatting.progressValue(for: status))
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(DriverRideFormatting.statusColor(for: status))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(BIRGEColors.surfaceElevated)
                    Capsule()
                        .fill(DriverRideFormatting.statusColor(for: status))
                        .frame(width: proxy.size.width * DriverRideFormatting.progressAmount(for: status))
                }
            }
            .frame(height: 8)
        }
    }
}

struct DriverPassengersCard: View {
    let inProgress: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack {
                Text(inProgress ? "ПАССАЖИРЫ В САЛОНЕ" : "ПАССАЖИРЫ")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Spacer()
                Text(inProgress ? "Полный" : "4 места")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.success)
                    .padding(.horizontal, BIRGELayout.xs)
                    .padding(.vertical, BIRGELayout.xxxs)
                    .background(Capsule().fill(BIRGEColors.success.opacity(0.12)))
            }

            HStack(spacing: -8) {
                ForEach(Array(["А", "М", "Д", "А"].enumerated()), id: \.offset) { _, initial in
                    Text(initial)
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.textOnBrand)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(DriverRideFormatting.avatarColor(for: initial)))
                        .overlay(Circle().stroke(BIRGEColors.background.opacity(0.8), lineWidth: 2))
                }
                Spacer()
                Label("Рейтинг 4.9", systemImage: "star.fill")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.warning)
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }
}

struct DriverBoardingCodesCard: View {
    private let codes = ["АС 142", "МК 809", "ДБ 317", "АМ 551"]

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text("КОДЫ ПОСАДКИ")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)

            ForEach(codes, id: \.self) { code in
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(BIRGEColors.success)
                    Text(code)
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Spacer()
                    Text("готов")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.04))
    }
}

struct DriverMetricChip: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: BIRGELayout.xxxs) {
            Image(systemName: icon)
            Text(value)
        }
        .font(BIRGEFonts.captionBold)
        .foregroundStyle(BIRGEColors.textPrimary)
        .padding(.horizontal, BIRGELayout.xs)
        .padding(.vertical, BIRGELayout.xxs)
        .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.05))
    }
}

private struct DriverGuidanceChip: View {
    let icon: String
    let value: String

    var body: some View {
        Label(value, systemImage: icon)
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(BIRGEColors.textPrimary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, BIRGELayout.xs)
            .padding(.vertical, BIRGELayout.xxs)
            .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.035))
    }
}
