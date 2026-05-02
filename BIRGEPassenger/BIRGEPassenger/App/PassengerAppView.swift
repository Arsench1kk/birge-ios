import SwiftUI
import ComposableArchitecture

struct PassengerAppView: View {
    @Bindable var store: StoreOf<PassengerAppFeature>

    var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            HomeView(
                store: store.scope(state: \.home, action: \.home)
            )
        } destination: { store in
            switch store.case {
            case .rideRequest(let store):
                RideRequestView(store: store)
            case .searching(let store):
                SearchingView(store: store)
            case .corridor(let store):
                CorridorPlaceholderView(store: store)
            #if DEBUG
            case .activeRide(let store):
                ActiveRideView(store: store)
            #endif
            case .ride(let store):
                RideMapView(store: store)
            case .rideComplete(let store):
                RideCompleteView(store: store)
            case .profile(let store):
                ProfileView(store: store)
            }
        }
    }
}

struct CorridorPlaceholderView: View {
    let store: StoreOf<CorridorFeature>

    var body: some View {
        VStack(spacing: 12) {
            Text(store.corridor.name)
                .font(.title3.weight(.bold))
            Text("Corridor detail — coming soon")
                .font(.subheadline)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .navigationTitle("Коридор")
        .navigationBarTitleDisplayMode(.inline)
    }
}
