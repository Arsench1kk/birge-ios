import BIRGECore
import ComposableArchitecture
import SwiftUI

struct ProductIntroStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.l) {
            BIRGESectionHeader(
                title: "Build your commute",
                subtitle: "BIRGE подбирает водителя и попутчиков для ваших ежедневных маршрутов.",
                systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill"
            )

            ProductIntroRouteMotif()

            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                ProductIntroPoint(index: 1, title: "Enter your addresses")
                ProductIntroPoint(index: 2, title: "Choose nearby pickup and dropoff nodes")
                ProductIntroPoint(index: 3, title: "Set your regular schedule")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProductIntroRouteMotif: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle().fill(BIRGEColors.brandPrimary).frame(width: 14, height: 14)
            Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 2)
            Image(systemName: "arrow.triangle.swap")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 34, height: 34)
                .background(BIRGEColors.brandPrimary.opacity(0.10))
                .clipShape(Circle())
            Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 2)
            Circle().fill(BIRGEColors.brandPrimary).frame(width: 14, height: 14)
        }
        .padding(BIRGELayout.l)
        .background(BIRGEColors.routeCanvasBackground)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
    }
}

private struct ProductIntroPoint: View {
    let index: Int
    let title: String

    var body: some View {
        Label {
            Text(title).font(BIRGEFonts.bodyMedium)
        } icon: {
            Text("\(index)")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(width: 26, height: 26)
                .background(BIRGEColors.brandPrimary)
                .clipShape(Circle())
        }
        .foregroundStyle(BIRGEColors.textPrimary)
    }
}

#Preview("Product Intro Step") {
    ProductIntroStepView()
        .padding(BIRGELayout.m)
        .background(BIRGEColors.passengerBackground)
}
