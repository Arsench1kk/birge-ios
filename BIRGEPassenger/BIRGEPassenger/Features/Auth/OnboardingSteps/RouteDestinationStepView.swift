//
//  RouteDestinationStepView.swift
//  BIRGEPassenger
//
//  Matches P-03b-route-destination.html:
//  "Куда вы едете?" — address search field + BIRGERouteCanvas (destination)
//  + BIRGENodeSelectorList for suggested dropoff nodes.
//  Step 2 of 5 in the first-route-entry flow.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

// MARK: - RouteDestinationStepView

struct RouteDestinationStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(
                title: "Куда вы едете?",
                subtitle: "Введите адрес работы или места назначения"
            )

            // Route canvas — destination role tints the end-node marker
            BIRGERouteCanvas(
                areaLabel: store.selectedDestinationAddress?.title,
                role: .destination
            )

            // Address search field
            AddressSearchField(
                placeholder: "Офис, ТРЦ или улица",
                text: Binding(
                    get: { store.destinationAddressQuery },
                    set: { store.send(.destinationQueryChanged($0)) }
                ),
                isLoading: store.isLoadingRouteData,
                identifierPrefix: "passenger_destination"
            )

            // Address search results
            if !store.destinationAddressResults.isEmpty {
                AddressResultList(
                    results: store.destinationAddressResults,
                    identifierPrefix: "passenger_destination_result"
                ) { result in
                    store.send(.destinationAddressSelected(result))
                }
            }

            // Confirmed address row
            if let selected = store.selectedDestinationAddress {
                SelectedValueRow(title: selected.title, subtitle: selected.fullAddress)
                    .accessibilityIdentifier("passenger_destination_selected")
            } else if !store.destinationAddressQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      store.destinationAddressResults.isEmpty,
                      !store.isLoadingRouteData {
                InsightLine(text: "Выберите адрес из списка, чтобы продолжить.")
                    .accessibilityIdentifier("passenger_destination_select_hint")
            }

            // Route preview strip once both ends are known
            if let origin = store.selectedOriginAddress,
               let destination = store.selectedDestinationAddress {
                RoutePreviewStrip(
                    originTitle: origin.title,
                    destinationTitle: destination.title
                )
                .accessibilityIdentifier("passenger_route_preview_strip")
            }
        }
        .accessibilityIdentifier("passenger_route_destination")
    }
}

// MARK: - RoutePreviewStrip
//
// Compact "Origin → Destination" confirmation strip shown at the bottom
// of the destination step once both addresses are selected.
// Mirrors the `.rm-route-strip` element in P-03b-route-destination.html.

private struct RoutePreviewStrip: View {
    let originTitle: String
    let destinationTitle: String

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.brandPrimary)

            Text("\(originTitle) → \(destinationTitle)")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Text("посадка и высадка выбраны")
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, BIRGELayout.s)
        .padding(.vertical, BIRGELayout.xs)
        .background(BIRGEColors.brandPrimary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .stroke(BIRGEColors.brandPrimary.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Destination — empty") {
    ScrollView {
        RouteDestinationStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .destinationAddress,
                selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0]
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Destination — results") {
    ScrollView {
        RouteDestinationStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .destinationAddress,
                selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0],
                destinationAddressQuery: "Esen",
                destinationAddressResults: BIRGEProductFixtures.Passenger.addressSearchResults
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Destination — both selected") {
    ScrollView {
        RouteDestinationStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .destinationAddress,
                selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0],
                selectedDestinationAddress: BIRGEProductFixtures.Passenger.addressSearchResults[1]
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}
