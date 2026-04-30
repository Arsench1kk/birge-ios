import SwiftUI
import ComposableArchitecture

@main
struct BIRGEPassengerApp: App {
    @State var store = Store(
        initialState: AppFeature.State()
    ) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
