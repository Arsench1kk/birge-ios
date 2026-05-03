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
            case .offerFound(let store):
                OfferFoundView(store: store)
            case .corridorList(let store):
                CorridorListView(store: store)
            case .corridorDetail(let store):
                CorridorDetailView(store: store)
            case .aiExplanation(let store):
                AIExplanationView(store: store)
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
