//
//  ProfileFeature.swift
//  BIRGEPassenger
//

import ComposableArchitecture
import Foundation

@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        var name: String = ""
        var phone: String = ""
        var rating: Double = 0.0
        var totalRides: Int = 0
        var isLoading: Bool = false
    }

    enum Action: Sendable {
        case onAppear
        case logoutTapped
        case delegate(Delegate)
        
        enum Delegate: Sendable {
            case loggedOut
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                // Mock loading data
                state.name = "Арсен"
                state.phone = "+7 777 123 4567"
                state.rating = 4.8
                state.totalRides = 23
                state.isLoading = false
                return .none
                
            case .logoutTapped:
                UserDefaults.standard.removeObject(forKey: "birge_auth_token")
                return .send(.delegate(.loggedOut))
                
            case .delegate:
                return .none
            }
        }
    }
}
