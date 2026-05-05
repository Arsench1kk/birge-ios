//
//  DriverDashboardSurfaces.swift
//  BIRGEDrive
//

import SwiftUI

struct DriverMapBackgroundView: View {
    let isOnline: Bool
    let hasActiveRide: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BIRGEColors.brandPrimary.opacity(0.16),
                    Color(.systemBackground),
                    BIRGEColors.success.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 34) {
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(BIRGEColors.textTertiary.opacity(0.08))
                        .frame(height: 1)
                }
            }
            .rotationEffect(.degrees(-14))
            .scaleEffect(1.35)

            HStack(spacing: 44) {
                ForEach(0..<8, id: \.self) { _ in
                    Rectangle()
                        .fill(BIRGEColors.textTertiary.opacity(0.06))
                        .frame(width: 1)
                }
            }
            .rotationEffect(.degrees(18))
            .scaleEffect(1.5)

            RoundedRectangle(cornerRadius: 32)
                .stroke(BIRGEColors.brandPrimary.opacity(0.24), style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [34, 22]))
                .frame(width: 260, height: 420)
                .rotationEffect(.degrees(27))
                .offset(x: -30, y: 78)

            RoundedRectangle(cornerRadius: 28)
                .stroke(BIRGEColors.success.opacity(0.24), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [24, 18]))
                .frame(width: 210, height: 320)
                .rotationEffect(.degrees(-22))
                .offset(x: 96, y: -120)

            if isOnline {
                DriverMapVehiclePulse(hasActiveRide: hasActiveRide)
                    .offset(y: -12)
            }
        }
    }
}

private struct DriverMapVehiclePulse: View {
    let hasActiveRide: Bool

    var body: some View {
        let color = hasActiveRide ? BIRGEColors.brandPrimary : BIRGEColors.success
        let ringSize: CGFloat = hasActiveRide ? 190 : 280
        let fillSize: CGFloat = hasActiveRide ? 136 : 210

        ZStack {
            Circle()
                .stroke(color.opacity(0.16), lineWidth: 24)
                .frame(width: ringSize, height: ringSize)
            Circle()
                .fill(color.opacity(0.08))
                .frame(width: fillSize, height: fillSize)
            Image(systemName: "car.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(width: 54, height: 54)
                .background(Circle().fill(BIRGEColors.brandPrimary))
                .shadow(color: BIRGEColors.brandPrimary.opacity(0.28), radius: 14, y: 7)

            if hasActiveRide {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(BIRGEColors.success))
                    .offset(x: 72, y: -58)
                    .shadow(color: BIRGEColors.success.opacity(0.24), radius: 12, y: 6)
            }
        }
    }
}

struct DriverTopBarView: View {
    let driverName: String
    let vehicleTitle: String
    let isOnline: Bool
    let isLoadingDriverProfile: Bool
    let todayTenge: Int
    let logoutTapped: () -> Void
    let earningsTapped: () -> Void

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(driverName)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(1)

                Text(vehicleTitle)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: BIRGELayout.xxs) {
                    Image(systemName: isOnline ? "dot.radiowaves.left.and.right" : "power")
                        .font(BIRGEFonts.captionBold)
                    Text(isOnline ? "Онлайн" : "Офлайн")
                        .font(BIRGEFonts.captionBold)
                }
                .foregroundStyle(isOnline ? BIRGEColors.success : BIRGEColors.textSecondary)
            }

            Spacer()

            if isLoadingDriverProfile {
                ProgressView()
                    .tint(BIRGEColors.brandPrimary)
                    .frame(width: 36, height: 36)
            }

            Menu {
                Button(action: earningsTapped) {
                    Label("Доходы", systemImage: "chart.line.uptrend.xyaxis")
                }
                Button(role: .destructive, action: logoutTapped) {
                    Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: BIRGELayout.minTapTarget, height: BIRGELayout.minTapTarget)
                    .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.08), isInteractive: true)
            }
            .accessibilityLabel("Аккаунт водителя")

            Button(action: earningsTapped) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(BIRGEFonts.captionBold)
                    Text("\(todayTenge)₸")
                        .font(BIRGEFonts.captionBold)
                }
                .foregroundStyle(BIRGEColors.success)
                .padding(.horizontal, BIRGELayout.xs)
                .padding(.vertical, BIRGELayout.xs)
                .liquidGlass(.pill, tint: BIRGEColors.success.opacity(0.08), isInteractive: true)
            }
            .accessibilityLabel("Заработок сегодня: \(todayTenge) тенге")
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.s)
        .padding(.bottom, BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))
        .padding(.horizontal, BIRGELayout.s)
        .padding(.top, BIRGELayout.xs)
    }
}

struct DriverOfflineCenterView: View {
    let driverProfileError: String?
    let startWork: () -> Void

    var body: some View {
        VStack(spacing: BIRGELayout.l) {
            ZStack {
                Circle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.12))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.08))
                    .frame(width: 110, height: 110)

                Image(systemName: "car.fill")
                    .font(BIRGEFonts.heroNumber)
                    .foregroundStyle(BIRGEColors.brandPrimary)
            }

            VStack(spacing: BIRGELayout.xxs) {
                Text("Вы офлайн")
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textPrimary)

                Text(driverProfileError ?? "Нажмите, чтобы начать принимать заказы")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(driverProfileError == nil ? BIRGEColors.textSecondary : BIRGEColors.danger)
                    .multilineTextAlignment(.center)
            }

            BIRGEPrimaryButton(title: "Начать работу", action: startWork)
                .padding(.horizontal, BIRGELayout.xl)
        }
        .padding(BIRGELayout.xl)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.05), isInteractive: true)
        .padding(.horizontal, BIRGELayout.m)
    }
}

struct DriverOnlineWaitingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: BIRGELayout.m) {
            ZStack {
                if reduceMotion {
                    ProgressView()
                        .tint(BIRGEColors.success)
                        .scaleEffect(1.3)
                } else {
                    DriverPulseRing(delay: 0.0, color: BIRGEColors.success)
                    DriverPulseRing(delay: 0.5, color: BIRGEColors.success)
                    DriverPulseRing(delay: 1.0, color: BIRGEColors.success)
                }

                Circle()
                    .fill(BIRGEColors.success)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "location.north.line.fill")
                            .font(BIRGEFonts.title)
                            .foregroundStyle(BIRGEColors.textOnBrand)
                    )
                    .shadow(color: BIRGEColors.success.opacity(0.32), radius: 18, y: 8)
            }
            .frame(width: 160, height: 160)

            VStack(spacing: BIRGELayout.xxs) {
                HStack(spacing: BIRGELayout.xxs) {
                    Circle()
                        .fill(BIRGEColors.success)
                        .frame(width: 8, height: 8)
                    Text("Онлайн • Ожидание")
                        .font(BIRGEFonts.sectionTitle)
                        .foregroundStyle(BIRGEColors.textPrimary)
                }
                Text("Сканируем ближайшие коридоры")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.vertical, BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.05))
        }
    }
}

struct DriverPulseRing: View {
    let delay: Double
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0.8

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .scaleEffect(scale)
            .onAppear {
                let animation = Animation.easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                withAnimation(reduceMotion ? nil : animation) {
                    scale = 1.6
                    opacity = 0
                }
            }
    }
}
