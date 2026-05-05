//
//  DriverActiveRideViews.swift
//  BIRGEDrive
//

import SwiftUI

struct DriverActiveRouteStatusView: View {
    let ride: DriverAppFeature.DriverActiveRide

    var body: some View {
        VStack(spacing: BIRGELayout.xs) {
            DriverNavigationCue(ride: ride)

            Label(
                DriverRideFormatting.statusText(for: ride.status),
                systemImage: DriverRideFormatting.statusIcon(for: ride.status)
            )
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(DriverRideFormatting.statusColor(for: ride.status))
            .padding(.horizontal, BIRGELayout.s)
            .padding(.vertical, BIRGELayout.xs)
            .liquidGlass(.pill, tint: DriverRideFormatting.statusColor(for: ride.status).opacity(0.08))

            HStack(spacing: BIRGELayout.xs) {
                DriverMetricChip(
                    icon: "clock.fill",
                    value: ride.status == .pickingUp ? "\(ride.etaMinutes) мин" : "~\(ride.etaMinutes) мин"
                )
                DriverMetricChip(
                    icon: "ruler.fill",
                    value: String(format: "%.1f км", ride.distanceKm)
                )
            }
        }
        .padding(.top, 72)
    }
}

struct DriverActiveRideSheet: View {
    let ride: DriverAppFeature.DriverActiveRide
    let callPassenger: () -> Void
    let performPrimaryAction: (DriverAppFeature.DriverActiveRide.RideStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            header
            DriverRouteProgress(status: ride.status)
            DriverNavigationPanel(ride: ride)
            routeCard

            if ride.status == .passengerWait {
                DriverBoardingCodesCard()
            } else {
                DriverPassengersCard(inProgress: ride.status == .inProgress)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BIRGELayout.xs), count: 2), spacing: BIRGELayout.xs) {
                DriverMetricTile(
                    icon: "clock",
                    label: ride.status == .pickingUp ? "До посадки" : "Осталось",
                    value: ride.status == .pickingUp ? "\(ride.etaMinutes) мин" : "~\(ride.etaMinutes) мин"
                )
                DriverMetricTile(
                    icon: "ruler",
                    label: "Маршрут",
                    value: String(format: "%.1f км", ride.distanceKm)
                )
            }

            BIRGEPrimaryButton(title: DriverRideFormatting.actionText(for: ride.status)) {
                performPrimaryAction(ride.status)
            }
        }
        .padding(BIRGELayout.m)
        .liquidGlass(
            .card,
            tint: DriverRideFormatting.statusColor(for: ride.status).opacity(0.06),
            isInteractive: true
        )
    }

    private var header: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: DriverRideFormatting.statusIcon(for: ride.status))
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(width: 44, height: 44)
                .background(Circle().fill(DriverRideFormatting.statusColor(for: ride.status)))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(DriverRideFormatting.statusText(for: ride.status))
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(DriverRideFormatting.statusSubtitle(for: ride))
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()

            Button(action: callPassenger) {
                Image(systemName: "phone.fill")
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 42, height: 42)
                    .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.08), isInteractive: true)
            }
            .accessibilityLabel("Позвонить пассажиру")
        }
    }

    private var routeCard: some View {
        VStack(spacing: BIRGELayout.xxs) {
            DriverRouteRow(
                icon: "location.circle.fill",
                color: BIRGEColors.success,
                label: ride.status == .pickingUp ? "Точка посадки" : "Посадка завершена",
                address: ride.pickup
            )
            DriverRouteRow(
                icon: "mappin.circle.fill",
                color: BIRGEColors.danger,
                label: "Назначение",
                address: ride.destination
            )
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: DriverRideFormatting.statusColor(for: ride.status).opacity(0.04))
    }
}

private struct DriverNavigationCue: View {
    let ride: DriverAppFeature.DriverActiveRide

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: DriverRideFormatting.maneuverSymbol(for: ride.status))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(width: 52, height: 52)
                .background(Circle().fill(DriverRideFormatting.statusColor(for: ride.status)))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(DriverRideFormatting.nextManeuverDistance(for: ride.status))
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Text(DriverRideFormatting.nextManeuverText(for: ride))
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(BIRGELayout.s)
        .frame(maxWidth: 320)
        .liquidGlass(
            .card,
            tint: DriverRideFormatting.statusColor(for: ride.status).opacity(0.08),
            isInteractive: true
        )
    }
}
