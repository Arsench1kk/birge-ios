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
            case .activeRide(let store):
                ActiveRideView(store: store)
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
