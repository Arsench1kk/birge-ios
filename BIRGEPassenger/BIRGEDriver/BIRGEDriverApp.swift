//
//  BIRGEDriverApp.swift
//  BIRGEDriver
//

import ComposableArchitecture
import SwiftUI

@main
struct BIRGEDriverApp: App {
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
                DriverAppView(store: store)
            } destination: { store in
                switch store.case {
                case .earnings(let store):
                    EarningsView(store: store)
                }
            }
        }
    }
}
