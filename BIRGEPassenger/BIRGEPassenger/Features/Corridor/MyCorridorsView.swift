import BIRGECore
import ComposableArchitecture
import SwiftUI

struct MyCorridorsView: View {
    @Bindable var store: StoreOf<MyCorridorsFeature>

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                header

                if store.isLoading {
                    ProgressView()
                        .tint(BIRGEColors.brandPrimary)
                        .frame(maxWidth: .infinity, minHeight: 140)
                        .liquidGlass(.card)
                }

                if let message = store.errorMessage {
                    BIRGEToast(message: message, style: .error)
                }

                if store.isEmpty {
                    emptyState
                }

                ForEach(store.bookings) { booking in
                    bookingCard(booking)
                }
            }
            .padding(BIRGELayout.m)
        }
        .background(background)
        .navigationTitle("Мои коридоры")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.send(.onAppear).finish()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                BIRGEColors.brandPrimary.opacity(0.10),
                BIRGEColors.background,
                BIRGEColors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
            Label("Регулярные поездки", systemImage: "point.topleft.filled.down.to.point.bottomright.curvepath")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.brandPrimary)
            Text("Здесь собраны коридоры, где ваше место уже сохранено.")
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))
    }

    private var emptyState: some View {
        VStack(spacing: BIRGELayout.xs) {
            Image(systemName: "map.circle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(BIRGEColors.brandPrimary)
            Text("Пока нет броней")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.textPrimary)
            Text("Выберите коридор на главной, и он появится здесь после подтверждения.")
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(BIRGELayout.l)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }

    private func bookingCard(_ booking: CorridorBookingItemDTO) -> some View {
        let corridor = CorridorOption(dto: booking.corridor)

        return Button {
            store.send(.bookingTapped(booking))
        } label: {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                HStack {
                    BIRGEMatchBadge(corridor.matchPercent)
                    Spacer()
                    Label(statusTitle(booking.status), systemImage: "checkmark.seal.fill")
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.success)
                }

                Text(corridor.name)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)

                HStack(spacing: BIRGELayout.xs) {
                    Label(corridor.departure, systemImage: "clock.fill")
                    Label("\(corridor.price)₸", systemImage: "tengesign.circle.fill")
                }
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)

                Text("Бронь \(booking.bookingID.prefix(8))")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textTertiary)
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.035), isInteractive: true)
        }
        .buttonStyle(BIRGEPressableButtonStyle())
    }

    private func statusTitle(_ status: String) -> String {
        status == "confirmed" ? "Активна" : status.capitalized
    }
}

#Preview {
    NavigationStack {
        MyCorridorsView(
            store: Store(initialState: MyCorridorsFeature.State()) {
                MyCorridorsFeature()
            }
        )
    }
}
