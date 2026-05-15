//
//  RouteOriginStepView.swift
//  BIRGEPassenger
//
//  Matches P-03a-route-origin.html:
//  "Где вы садитесь?" — address search field + BIRGERouteCanvas (origin)
//  + BIRGENodeSelectorList for suggested pickup nodes.
//  Step 1 of 5 in the first-route-entry flow.
//

import BIRGECore
import ComposableArchitecture
import SwiftUI

// MARK: - RouteOriginStepView

struct RouteOriginStepView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            SetupHero(
                title: "Где вы садитесь?",
                subtitle: "Введите адрес или выберите точку рядом"
            )

            // Route canvas — shows origin area label once an address is selected
            BIRGERouteCanvas(
                areaLabel: store.selectedOriginAddress?.title,
                role: .origin
            )

            // Address search field
            AddressSearchField(
                placeholder: "Дом, ЖК или улица",
                text: Binding(
                    get: { store.originAddressQuery },
                    set: { store.send(.originQueryChanged($0)) }
                ),
                isLoading: store.isLoadingRouteData,
                identifierPrefix: "passenger_origin"
            )

            // Address search results
            if !store.originAddressResults.isEmpty {
                AddressResultList(
                    results: store.originAddressResults,
                    identifierPrefix: "passenger_origin_result"
                ) { result in
                    store.send(.originAddressSelected(result))
                }
            }

            // Confirmed address confirmation row
            if let selected = store.selectedOriginAddress {
                SelectedValueRow(title: selected.title, subtitle: selected.fullAddress)
                    .accessibilityIdentifier("passenger_origin_selected")
            } else if !store.originAddressQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      store.originAddressResults.isEmpty,
                      !store.isLoadingRouteData {
                InsightLine(text: "Выберите адрес из списка, чтобы продолжить.")
                    .accessibilityIdentifier("passenger_origin_select_hint")
            }

            InsightLine(text: "Точные адреса не показываются попутчикам.")
        }
        .accessibilityIdentifier("passenger_route_origin")
    }
}

// MARK: - AddressSearchField
//
// Shared by RouteOriginStepView and RouteDestinationStepView.
// Internal visibility so both files in the same target can use it.

struct AddressSearchField: View {
    let placeholder: String
    let text: Binding<String>
    let isLoading: Bool
    let identifierPrefix: String

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BIRGEColors.textTertiary)

            TextField(placeholder, text: text)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textPrimary)
                .tint(BIRGEColors.brandPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("\(identifierPrefix)_field")

            if isLoading {
                ProgressView()
                    .tint(BIRGEColors.brandPrimary)
                    .scaleEffect(0.8)
                    .accessibilityIdentifier("\(identifierPrefix)_loading")
            } else if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(BIRGEColors.textTertiary)
                }
                .accessibilityLabel("Очистить")
            }
        }
        .padding(.horizontal, BIRGELayout.s)
        .frame(height: 50)
        .background(BIRGEColors.passengerSurface)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - AddressResultRow
//
// Single address search result row used inside AddressResultList.

struct AddressResultRow: View {
    let result: MockAddressSearchResult

    var body: some View {
        HStack(alignment: .top, spacing: BIRGELayout.xs) {
            Image(systemName: "mappin.circle")
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 30, height: 30)
                .background(BIRGEColors.brandPrimary.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(result.title)
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(result.subtitle)
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Text(result.fullAddress)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textTertiary)
            }

            Spacer(minLength: BIRGELayout.xs)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.textTertiary)
        }
        .padding(BIRGELayout.s)
        .background(BIRGEColors.passengerSurface)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - AddressResultList
//
// Shared by RouteOriginStepView and RouteDestinationStepView.

struct AddressResultList: View {
    let results: [MockAddressSearchResult]
    let identifierPrefix: String
    let onSelect: (MockAddressSearchResult) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                Button {
                    onSelect(result)
                } label: {
                    AddressResultRow(result: result)
                }
                .buttonStyle(BIRGEPressableButtonStyle())
                .accessibilityIdentifier("\(identifierPrefix)_\(result.id.uuidString)")

                if index < results.count - 1 {
                    Divider()
                        .background(BIRGEColors.borderSubtle)
                        .padding(.leading, BIRGELayout.s + 30 + BIRGELayout.xs)
                }
            }
        }
        .background(BIRGEColors.passengerSurface)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                .stroke(BIRGEColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Origin — empty") {
    ScrollView {
        RouteOriginStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .originAddress
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Origin — results") {
    ScrollView {
        RouteOriginStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .originAddress,
                originAddressQuery: "Ala",
                originAddressResults: BIRGEProductFixtures.Passenger.addressSearchResults
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}

#Preview("Origin — selected") {
    ScrollView {
        RouteOriginStepView(
            store: Store(initialState: OnboardingFeature.State(
                initialStep: .firstRouteEntry,
                routeStep: .originAddress,
                selectedOriginAddress: BIRGEProductFixtures.Passenger.addressSearchResults[0]
            )) {
                OnboardingFeature()
            }
        )
        .padding(.horizontal, BIRGELayout.m)
    }
    .background(BIRGEColors.passengerBackground)
}
