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
                switch store.root {
                case .auth:
                    DriverAuthView(
                        store: store.scope(state: \.auth, action: \.auth)
                    )
                case .dashboard, .activeRide:
                    DriverAppView(store: store)
                case .registration:
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
