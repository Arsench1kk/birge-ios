//
//  DriverRidePrimitives.swift
//  BIRGEDrive
//

import SwiftUI

struct DriverRouteRow: View {
    let icon: String
    let color: Color
    let label: String
    let address: String

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: icon)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(label)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Text(address)
                    .font(label == "Назначение" ? BIRGEFonts.bodyMedium : BIRGEFonts.body)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(2)
            }
        }
    }
}

struct DriverMetricTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: icon)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(BIRGEColors.brandPrimary.opacity(0.1)))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(value)
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(label)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }
}

struct DriverPassengerAvatar: View {
    let name: String

    var body: some View {
        Text(String(name.prefix(1)))
            .font(BIRGEFonts.bodyMedium)
            .foregroundStyle(BIRGEColors.textOnBrand)
            .frame(width: 42, height: 42)
            .background(Circle().fill(BIRGEColors.brandPrimary))
            .overlay(Circle().stroke(BIRGEColors.background.opacity(0.72), lineWidth: 2))
    }
}
