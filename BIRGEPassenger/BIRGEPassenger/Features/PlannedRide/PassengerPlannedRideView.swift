import BIRGECore
import ComposableArchitecture
import SwiftUI

@ViewAction(for: PassengerPlannedRideFeature.self)
struct PassengerPlannedRideView: View {
    @Bindable var store: StoreOf<PassengerPlannedRideFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BIRGELayout.m) {
                if store.isLoading {
                    ProgressView()
                }

                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.danger)
                }

                if let ride = store.plannedRide {
                    rideSummary(ride)
                    driverSummary(ride)
                    boardingCode(ride)
                    timeline(ride)
                    edgeCase(ride)
                    actions(ride)
                }
            }
            .padding(BIRGELayout.m)
        }
        .background(BIRGEColors.background.ignoresSafeArea())
        .navigationTitle("Planned ride")
        .task {
            send(.onAppear)
        }
    }

    private func rideSummary(_ ride: MockPlannedCommuteRide) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Text(ride.routeName)
                .font(BIRGEFonts.title)
            Text(ride.status.rawValue)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.brandPrimary)
            Text(ride.etaText)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
            Text(ride.departureWindow)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
            Text(ride.pickupNode.title)
                .font(BIRGEFonts.bodyMedium)
            Text(ride.dropoffNode.title)
                .font(BIRGEFonts.bodyMedium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BIRGELayout.s)
        .background(BIRGEColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
    }

    @ViewBuilder
    private func driverSummary(_ ride: MockPlannedCommuteRide) -> some View {
        if let driver = ride.driver, let vehicle = ride.vehicle {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                Text(driver.displayName)
                    .font(BIRGEFonts.bodyMedium)
                Text("\(vehicle.color) \(vehicle.make) \(vehicle.model)")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Text(vehicle.plateNumber)
                    .font(BIRGEFonts.captionBold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIRGELayout.s)
            .background(BIRGEColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
        }
    }

    @ViewBuilder
    private func boardingCode(_ ride: MockPlannedCommuteRide) -> some View {
        if let code = ride.boardingCode,
           ride.status == .boarding || ride.status == .driverArrived || ride.status == .driverEnRoute {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                Text(code.value)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                Text("\(code.refreshesInSeconds)s")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIRGELayout.s)
            .background(BIRGEColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
        }
    }

    private func timeline(_ ride: MockPlannedCommuteRide) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            ForEach(ride.timeline) { item in
                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(item.title)
                        .font(BIRGEFonts.bodyMedium)
                    Text(item.detail)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func edgeCase(_ ride: MockPlannedCommuteRide) -> some View {
        if let edgeCase = ride.edgeCase {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                Text(edgeCase.title)
                    .font(BIRGEFonts.bodyMedium)
                Text(edgeCase.body)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Button(edgeCase.actionTitle) {
                    send(.reportIssueTapped)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIRGELayout.s)
            .background(BIRGEColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
        }
    }

    @ViewBuilder
    private func actions(_ ride: MockPlannedCommuteRide) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            if store.isAdvancing {
                ProgressView()
            }

            switch ride.status {
            case .driverEnRoute:
                Button("Arrived") { send(.driverArrivedTapped) }
            case .driverArrived:
                Button("Show code") { send(.showBoardingCodeTapped) }
            case .boarding:
                Button("Confirm boarding") { send(.boardingConfirmedTapped) }
            case .inProgress:
                Button("Complete") { send(.rideCompletedTapped) }
            case .completed:
                if let summary = store.completedSummary {
                    Text(summary.title)
                        .font(BIRGEFonts.bodyMedium)
                    Text(summary.arrivalText)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
                Button("Done") { send(.doneTapped) }
            default:
                Button("Advance") { send(.advanceMockLifecycleTapped) }
            }

            HStack {
                Button("Report") { send(.reportIssueTapped) }
                Button("Support") { send(.supportTapped) }
                Button("Safety") { send(.safetyTapped) }
                Button("Share") { send(.shareStatusTapped) }
            }
            .buttonStyle(.bordered)
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    PassengerPlannedRideView(
        store: Store(
            initialState: PassengerPlannedRideFeature.State(
                plannedRide: BIRGEProductFixtures.Passenger.plannedCommuteRide
            )
        ) {
            PassengerPlannedRideFeature()
        }
    )
}
