import BIRGECore
import ComposableArchitecture
import SwiftUI

struct MyCorridorsView: View {
    @Bindable var store: StoreOf<MyCorridorsFeature>

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

                switch store.mode {
                case .list:
                    routeList
                case .detail:
                    routeDetail
                case let .addRouteDraft(draft):
                    draftPlaceholder(draft)
                case let .editRouteDraft(route):
                    routePlaceholder(route)
                case let .editPickup(route):
                    routePlaceholder(route)
                case let .editDropoff(route):
                    routePlaceholder(route)
                case let .editSchedule(route):
                    routePlaceholder(route)
                }
            }
            .padding(BIRGELayout.m)
        }
        .background(BIRGEColors.background.ignoresSafeArea())
        .navigationTitle("My Routes")
        .task {
            await store.send(.onAppear).finish()
        }
    }

    private var routeList: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            Button("Add") {
                store.send(.addRouteTapped)
            }
            .buttonStyle(.bordered)

            if store.isEmpty {
                Text("No routes")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            ForEach(store.routes) { route in
                Button {
                    store.send(.routeTapped(route.id))
                } label: {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(route.name)
                            .font(BIRGEFonts.bodyMedium)
                        Text("\(route.originName) -> \(route.destinationName)")
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                        Text(route.status.rawValue)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.brandPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private var routeDetail: some View {
        if let route = store.selectedRoute {
            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                Text(route.name)
                    .font(BIRGEFonts.title)
                Text(route.status.rawValue)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                Text(route.pickupNode.title)
                Text(route.dropoffNode.title)
                Text("\(route.schedule.departureWindowStart)-\(route.schedule.departureWindowEnd)")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)

                if let detail = store.selectedStatusDetail {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(detail.title)
                        Text(detail.body)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                        if let waitlistPosition = detail.waitlistPosition {
                            Text("\(waitlistPosition)")
                                .font(BIRGEFonts.caption)
                        }
                        Button(detail.actionTitle) {
                            store.send(.routeStatusActionTapped)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button("Edit") { store.send(.editRouteTapped) }
                Button("Pickup") { store.send(.editPickupTapped) }
                Button("Dropoff") { store.send(.editDropoffTapped) }
                Button("Schedule") { store.send(.editScheduleTapped) }

                if route.status == .paused {
                    Button("Resume") { store.send(.resumeRouteTapped) }
                } else {
                    Button("Pause") { store.send(.pauseRouteTapped) }
                }
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func draftPlaceholder(_ draft: MockRouteDraft?) -> some View {
        if let draft {
            Text(draft.displayName)
                .font(BIRGEFonts.bodyMedium)
        }
    }

    private func routePlaceholder(_ route: MockRecurringRoute) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.s) {
            Text(route.name)
                .font(BIRGEFonts.bodyMedium)
            Button("Save") {
                store.send(.saveEditedRoutePlaceholderTapped)
            }
            .buttonStyle(.bordered)
        }
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
