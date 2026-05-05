//
//  DriverOfferViews.swift
//  BIRGEDrive
//

import SwiftUI

struct DriverOfferAlertView: View {
    let offer: DriverAppFeature.RideOffer

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "bell.badge.fill")
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(width: 42, height: 42)
                .background(Circle().fill(BIRGEColors.success))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Новый заказ")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("\(offer.etaMinutes) мин до подачи • \(offer.fare)₸")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textTertiary)
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.07), isInteractive: true)
        .shadow(color: BIRGEColors.success.opacity(0.14), radius: 18, y: 8)
    }
}

struct DriverOfferSheet: View {
    let offer: DriverAppFeature.RideOffer
    let secondsRemaining: Int
    let reduceMotion: Bool
    let accept: () -> Void
    let decline: () -> Void

    var body: some View {
        BIRGEGlassSheet {
            BIRGESheetHandle()

            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                header
                routeCard
                metricsGrid
                passengerConfirmation

                VStack(spacing: BIRGELayout.xs) {
                    BIRGEPrimaryButton(title: "Принять", action: accept)
                    BIRGESecondaryButton(title: "Отклонить", action: decline)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: BIRGELayout.s) {
            countdownRing

            VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                HStack(spacing: BIRGELayout.xxs) {
                    Image(systemName: "sparkles")
                        .font(BIRGEFonts.captionBold)
                    Text("98% совпадение")
                        .font(BIRGEFonts.captionBold)
                }
                .foregroundStyle(BIRGEColors.brandPrimary)
                .padding(.horizontal, BIRGELayout.xs)
                .padding(.vertical, BIRGELayout.xxs)
                .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.08))

                Text(offer.passengerName)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("Комфортный маршрут рядом с вашей зоной")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: BIRGELayout.xxxs) {
                Text("\(offer.fare)₸")
                    .font(BIRGEFonts.heroNumber)
                    .foregroundStyle(BIRGEColors.success)
                Text("за поездку")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
        }
    }

    private var routeCard: some View {
        VStack(spacing: BIRGELayout.xxs) {
            DriverRouteRow(
                icon: "circle.fill",
                color: BIRGEColors.success,
                label: "Забрать",
                address: offer.pickup
            )
            DriverRouteRow(
                icon: "mappin.circle.fill",
                color: BIRGEColors.danger,
                label: "Назначение",
                address: offer.destination
            )
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.035))
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BIRGELayout.xs), count: 2), spacing: BIRGELayout.xs) {
            DriverMetricTile(icon: "ruler", label: "Дистанция", value: "\(String(format: "%.1f", offer.distanceKm)) км")
            DriverMetricTile(icon: "clock", label: "До подачи", value: "\(offer.etaMinutes) мин")
            DriverMetricTile(icon: "person.2.fill", label: "Пассажиры", value: "1 место")
            DriverMetricTile(icon: "bolt.car.fill", label: "Приоритет", value: "Высокий")
        }
    }

    private var passengerConfirmation: some View {
        HStack(spacing: BIRGELayout.xs) {
            DriverPassengerAvatar(name: offer.passengerName)
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Пассажир подтвержден")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("Рейтинг 4.9 • оплата в приложении")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            Spacer()
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.04))
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(BIRGEColors.surfaceElevated, lineWidth: 7)
                .frame(width: 64, height: 64)
            Circle()
                .trim(from: 0, to: CGFloat(max(secondsRemaining, 0)) / 15)
                .stroke(countdownColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 64, height: 64)
                .animation(reduceMotion ? nil : .linear(duration: 1), value: secondsRemaining)
            Text("\(secondsRemaining)")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(countdownColor)
        }
        .accessibilityLabel("Осталось \(secondsRemaining) секунд")
    }

    private var countdownColor: Color {
        if secondsRemaining <= 3 {
            return BIRGEColors.danger
        } else if secondsRemaining <= 7 {
            return BIRGEColors.warning
        }
        return BIRGEColors.success
    }
}
