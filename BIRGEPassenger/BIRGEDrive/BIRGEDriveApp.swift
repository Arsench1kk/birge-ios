//
//  BIRGEDriveApp.swift
//  BIRGEDrive
//

import ComposableArchitecture
import SwiftUI

@main
struct BIRGEDriveApp: App {
    @State var store = Store(
        initialState: DriverAppFeature.State()
    ) {
        DriverAppFeature()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(
                path: $store.scope(state: \.path, action: \.path)
            ) {
                if store.isRegistrationComplete {
                    DriverAppView(store: store)
                } else {
                    DriverRegistrationView(
                        store: store.scope(state: \.registration, action: \.registration)
                    )
                }
            } destination: { store in
                switch store.case {
                case .earnings(let store):
                    EarningsView(store: store)
                }
            }
            .task {
                store.send(.task)
            }
        }
    }
}
