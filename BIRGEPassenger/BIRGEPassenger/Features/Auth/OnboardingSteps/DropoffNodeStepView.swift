//
//  DropoffNodeStepView.swift
//  BIRGEPassenger
//
//  Matches the dropoff-node selection phase of P-03b-route-destination.html:
//  BIRGERouteCanvas (destination) + "Ближайшие точки высадки" label
//  + BIRGENodeSelectorList + privacy insight line.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

// MARK: - DropoffNodeStepView

struct DropoffNodeStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(
                title: "Точка высадки",
                subtitle: "Выберите ближайшую точку к вашему месту назначения"
            )

            // Canvas shows the destination area label; destination role tints end-node
            BIRGERouteCanvas(
                areaLabel: store.selectedDestinationAddress?.title,
                role: .destination
            )

            // Section label
            Text("Ближайшие точки высадки")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)

            // Node list or empty state
            if store.suggestedDropoffNodes.isEmpty {
                EmptyStateRow(
                    systemImage: "mappin.slash",
                    title: "Сначала выберите адрес назначения"
                )
                .accessibilityIdentifier("passenger_dropoff_node_empty")
            } else {
                BIRGENodeSelectorList(
                    nodes: store.suggestedDropoffNodes,
                    selectedID: store.selectedDropoffNodeID,
                    role: .destination
                ) { node in
                    store.send(.dropoffNodeSelected(node.id))
                }
                .accessibilityIdentifier("passenger_dropoff_node_list")
            }

            InsightLine(text: "Точные адреса не показываются попутчикам.")
        }
        .accessibilityIdentifier("passenger_dropoff_node")
    }
}

// MARK: - Preview

#Preview("Dropoff — nodes available") {
    ScrollView {
        DropoffNodeStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .dropoffNode,
                selectedDestinationAddress: BIRGEProductFixtures.Passenger.addressSearchResults[1],
                suggestedDropoffNodes: BIRGEProductFixtures.Passenger.dropoffNodes
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Dropoff — node selected") {
    ScrollView {
        DropoffNodeStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .dropoffNode,
                selectedDestinationAddress: BIRGEProductFixtures.Passenger.addressSearchResults[1],
                suggestedDropoffNodes: BIRGEProductFixtures.Passenger.dropoffNodes,
                selectedDropoffNodeID: BIRGEProductFixtures.Passenger.dropoffNodes[0].id
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Dropoff — empty (no destination selected)") {
    ScrollView {
        DropoffNodeStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .dropoffNode
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}
