//
//  DriverAppView.swift
//  BIRGEDrive
//

import ComposableArchitecture
import SwiftUI

struct DriverAppView: View {
    @Bindable var store: StoreOf<DriverAppFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offerSecondsRemaining = 15
    @State private var offerTimerTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            DriverMapBackgroundView(
                isOnline: store.isOnline,
                hasActiveRide: store.activeRide != nil
            )
                .ignoresSafeArea()

            VStack(spacing: 0) {
                DriverTopBarView(
                    driverName: store.driverName,
                    vehicleTitle: store.vehicleTitle,
                    isOnline: store.isOnline,
                    isLoadingDriverProfile: store.isLoadingDriverProfile,
                    todayTenge: store.earnings.todayTenge
                ) {
                    store.send(.earningsTapped)
                }
                Spacer()
                centerContent
                Spacer()
            }

            if let offer = store.currentOffer {
                DriverOfferAlertView(offer: offer)
                    .padding(.horizontal, BIRGELayout.m)
                    .padding(.top, 112)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if store.isOnline && store.activeRide == nil && store.currentOffer == nil {
                DriverOnlineControlSheet(
                    earnings: store.earnings,
                    isLoadingTodayCorridors: store.isLoadingTodayCorridors,
                    todayCorridorsError: store.todayCorridorsError,
                    todayCorridors: store.todayCorridors
                ) {
                    store.send(.toggleOnline)
                }
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let offer = store.currentOffer {
                DriverOfferSheet(
                    offer: offer,
                    secondsRemaining: offerSecondsRemaining,
                    reduceMotion: reduceMotion,
                    accept: { store.send(.acceptOffer) },
                    decline: { store.send(.declineOffer) }
                )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let ride = store.activeRide {
                DriverActiveRideSheet(
                    ride: ride,
                    callPassenger: {},
                    performPrimaryAction: performActiveRideAction
                )
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let summary = store.completedRideSummary {
                DriverCompletedRideSheet(
                    summary: summary,
                    findNextRide: { store.send(.findNextRide) },
                    dismiss: { store.send(.dismissCompletedRide) }
                )
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: store.currentOffer != nil)
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: store.activeRide != nil)
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: store.completedRideSummary != nil)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: store.isOnline)
        .onChange(of: store.currentOffer != nil) { _, hasOffer in
            if hasOffer {
                startOfferCountdown()
            } else {
                offerTimerTask?.cancel()
                offerSecondsRemaining = 15
            }
        }
        .onDisappear {
            offerTimerTask?.cancel()
        }
        .navigationBarHidden(true)
    }

    // MARK: - Center Content

    @ViewBuilder
    private var centerContent: some View {
        if let ride = store.activeRide {
            DriverActiveRouteStatusView(ride: ride)
        } else if !store.isOnline {
            DriverOfflineCenterView(driverProfileError: store.driverProfileError) {
                store.send(.toggleOnline)
            }
        } else {
            DriverOnlineWaitingView()
        }
    }

    private func performActiveRideAction(_ status: DriverAppFeature.DriverActiveRide.RideStatus) {
        switch status {
        case .pickingUp:
            store.send(.arrivedAtPickup)
        case .passengerWait:
            store.send(.startRide)
        case .inProgress:
            store.send(.completeRide)
        }
    }

    private func startOfferCountdown() {
        offerTimerTask?.cancel()
        offerSecondsRemaining = 15
        offerTimerTask = Task { @MainActor in
            while offerSecondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                offerSecondsRemaining -= 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DriverAppView(
            store: Store(initialState: DriverAppFeature.State()) {
                DriverAppFeature()
            }
        )
    }
}
