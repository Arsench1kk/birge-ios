//
//  ProfileFeature.swift
//  BIRGEPassenger
//

import BIRGECore
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
        var errorMessage: String?
    }

    enum Action: Sendable {
        case onAppear
        case profileLoaded(CurrentUserResponse)
        case profileLoadFailed(String)
        case logoutTapped
        case delegate(Delegate)
        
        enum Delegate: Sendable {
            case loggedOut
        }
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.tokenRefreshClient) var tokenRefreshClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let user = try await apiClient.currentUser()
                        await send(.profileLoaded(user))
                    } catch {
                        if Self.isUnauthorized(error) {
                            await send(.delegate(.loggedOut))
                        } else {
                            await send(.profileLoadFailed(error.localizedDescription))
                        }
                    }
                }

            case let .profileLoaded(user):
                state.isLoading = false
                state.errorMessage = nil
                state.name = user.name ?? ""
                state.phone = user.phone
                state.rating = user.rating ?? 0
                state.totalRides = user.totalRides ?? 0
                return .none

            case let .profileLoadFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case .logoutTapped:
                return .run { send in
                    try? await tokenRefreshClient.clearTokens()
                    await send(.delegate(.loggedOut))
                }
                
            case .delegate:
                return .none
            }
        }
    }

    nonisolated private static func isUnauthorized(_ error: any Error) -> Bool {
        guard let apiError = error as? BIRGEAPIError else { return false }
        return [
            "UNAUTHORIZED",
            "INVALID_REFRESH_TOKEN",
            "MISSING_REFRESH_TOKEN",
            "MISSING_ACCESS_TOKEN"
        ].contains(apiError.errorCode)
    }
}
