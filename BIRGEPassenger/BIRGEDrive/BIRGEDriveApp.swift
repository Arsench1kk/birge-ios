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
