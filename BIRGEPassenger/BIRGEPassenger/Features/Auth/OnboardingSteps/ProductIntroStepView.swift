import BIRGECore
import ComposableArchitecture
import SwiftUI

struct ProductIntroStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xl) {
            SetupHero(
                title: "Настроим первый маршрут",
                subtitle: "Сначала укажете адреса, потом выберете удобные точки посадки и высадки.",
                maxTitleWidth: 260
            )

            ProductIntroRouteMotif()

            Text("Дальше BIRGE предложит ближайшие удобные точки.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, BIRGELayout.xl)
    }
}

private struct ProductIntroRouteMotif: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            BIRGEColors.brandPrimary,
                            BIRGEColors.brandPrimary.opacity(0.22)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .clipShape(Capsule())
                .rotationEffect(.degrees(-5))
                .padding(.horizontal, 42)
                .offset(y: -20)

            HStack(spacing: BIRGELayout.s) {
                ProductIntroMilestone(title: "Адреса", isActive: true)
                ProductIntroMilestone(title: "Точки")
                ProductIntroMilestone(title: "Расписание")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 118)
        .padding(.horizontal, BIRGELayout.s)
    }
}

private struct ProductIntroMilestone: View {
    let title: String
    var isActive = false

    var body: some View {
        VStack(spacing: BIRGELayout.xs) {
            Circle()
                .fill(isActive ? BIRGEColors.brandPrimary : BIRGEColors.brandPrimary.opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(BIRGEColors.passengerBackground, lineWidth: 4))
                .shadow(
                    color: isActive ? BIRGEColors.brandPrimary.opacity(0.18) : .clear,
                    radius: 0,
                    x: 0,
                    y: 0
                )
                .overlay {
                    if isActive {
                        Circle()
                            .stroke(BIRGEColors.brandPrimary.opacity(0.10), lineWidth: 8)
                    }
                }

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isActive ? BIRGEColors.textPrimary : BIRGEColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Product Intro Step") {
    ProductIntroStepView()
        .padding(BIRGELayout.m)
        .background(BIRGEColors.passengerBackground)
}
