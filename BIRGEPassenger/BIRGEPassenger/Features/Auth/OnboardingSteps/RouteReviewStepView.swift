//
//  RouteReviewStepView.swift
//  BIRGEPassenger
//
//  Matches P-03d-route-review.html:
//  review the recurring route draft before monthly plan selection.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

// MARK: - RouteReviewStepView

struct RouteReviewStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(
                title: "Review route",
                subtitle: "Confirm this recurring commute before monthly plans"
            )

            if let draft = store.routeDraftForReview {
                BIRGERouteReviewTicket(draft: draft)
                    .accessibilityIdentifier("passenger_route_review_card")
            } else {
                EmptyStateRow(systemImage: "exclamationmark.circle", title: "Route details incomplete")
                    .accessibilityIdentifier("passenger_route_review_empty")
            }
        }
        .accessibilityIdentifier("passenger_route_review")
    }
}

// MARK: - Previews

#Preview("Review — complete draft") {
    ScrollView {
        RouteReviewStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .review,
                routeDraft: BIRGEProductFixtures.Passenger.draftRoute,
                selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0],
                suggestedPickupNodes: BIRGEProductFixtures.Passenger.pickupNodes,
                selectedPickupNodeID: BIRGEProductFixtures.Passenger.pickupNodes[0].id,
                selectedDestinationAddress: BIRGEProductFixtures.Passenger.addressSearchResults[1],
                suggestedDropoffNodes: BIRGEProductFixtures.Passenger.dropoffNodes,
                selectedDropoffNodeID: BIRGEProductFixtures.Passenger.dropoffNodes[0].id,
                selectedWeekdays: Set(BIRGEProductFixtures.Passenger.morningSchedule.weekdays),
                departureTime: BIRGEProductFixtures.Passenger.morningSchedule.departureWindowStart,
                flexibilityMinutes: 30
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Review — incomplete") {
    ScrollView {
        RouteReviewStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .review
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}
