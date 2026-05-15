//
//  PickupNodeStepView.swift
//  BIRGEPassenger
//
//  Matches the pickup-node selection phase of P-03a-route-origin.html:
//  BIRGERouteCanvas (origin) + "Ближайшие точки посадки" label
//  + BIRGENodeSelectorList + privacy insight line.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

// MARK: - PickupNodeStepView

struct PickupNodeStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(
                title: "Точка посадки",
                subtitle: "Выберите ближайшую точку к вашему адресу"
            )

            // Canvas shows the origin area label
            BIRGERouteCanvas(
                areaLabel: store.selectedOriginAddress?.title,
                role: .origin
            )

            // Section label
            Text("Ближайшие точки посадки")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)

            // Node list or empty state
            if store.suggestedPickupNodes.isEmpty {
                EmptyStateRow(
                    systemImage: "mappin.slash",
                    title: "Сначала выберите адрес отправления"
                )
                .accessibilityIdentifier("passenger_pickup_node_empty")
            } else {
                BIRGENodeSelectorList(
                    nodes: store.suggestedPickupNodes,
                    selectedID: store.selectedPickupNodeID,
                    role: .origin
                ) { node in
                    store.send(.pickupNodeSelected(node.id))
                }
                .accessibilityIdentifier("passenger_pickup_node_list")
            }

            InsightLine(text: "Точные адреса не показываются попутчикам.")
        }
        .accessibilityIdentifier("passenger_pickup_node")
    }
}

// MARK: - Preview

#Preview("Pickup — nodes available") {
    ScrollView {
        PickupNodeStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .pickupNode,
                selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0],
                suggestedPickupNodes: BIRGEProductFixtures.Passenger.pickupNodes
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Pickup — node selected") {
    ScrollView {
        PickupNodeStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .pickupNode,
                selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0],
                suggestedPickupNodes: BIRGEProductFixtures.Passenger.pickupNodes,
                selectedPickupNodeID: BIRGEProductFixtures.Passenger.pickupNodes[0].id
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Pickup — empty (no origin selected)") {
    ScrollView {
        PickupNodeStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .pickupNode
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}
