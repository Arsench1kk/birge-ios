//
//  AppFeature.swift
//  BIRGEPassenger
//

import BIRGECore
import ComposableArchitecture
import Foundation

// MARK: - AppFeature

struct PassengerAuthRouting: Equatable, Sendable {
    var phoneNumber: String?
    var decision: PassengerAuthDecision
}

@Reducer
struct AppFeature {

    @ObservableState
    enum State: Equatable {
        case splash(SplashFeature.State)
        case needsOnboarding(OnboardingFeature.State)
        case unauthenticated(OTPFeature.State)
        case authenticated(PassengerAppFeature.State)

        init() {
            self = .splash(SplashFeature.State())
        }
    }

    @CasePathable
    enum Action: Sendable {
        case splash(SplashFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case otp(OTPFeature.Action)
        case passengerApp(PassengerAppFeature.Action)
        case passengerAuthDecisionResolved(PassengerAuthRouting)
    }

    @Dependency(\.keychainClient) var keychainClient
    @Dependency(\.mockSessionClient) var mockSessionClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // Splash -> mock session decision
            case .splash(.delegate(.splashFinished)):
                return .run { send in
                    guard let session = await mockSessionClient.currentSession(),
                          session.role == .passenger else {
                        await send(.passengerAuthDecisionResolved(PassengerAuthRouting(
                            phoneNumber: nil,
                            decision: .phoneLogin
                        )))
                        return
                    }
                    let decision = await mockSessionClient.passengerAuthDecision(session.phoneNumber)
                    await send(.passengerAuthDecisionResolved(PassengerAuthRouting(
                        phoneNumber: session.phoneNumber,
                        decision: decision
                    )))
                }

            case .splash:
                return .none

            case let .onboarding(.delegate(.routeDraftReadyForSubscription(routeDraft))):
                var passengerState = PassengerAppFeature.State()
                passengerState.path.append(.subscriptions(SubscriptionsFeature.State(routeDraft: routeDraft)))
                state = .authenticated(passengerState)
                return .none

            case .onboarding(.delegate(.readyForFirstRouteSetup)):
                return .none

            case .onboarding:
                return .none

            // OTP -> passenger auth decision
            case .otp(.delegate(.authenticated(let authentication))):
                guard authentication.role == "passenger" else {
                    state = .unauthenticated(OTPFeature.State())
                    return .none
                }
                return .run { send in
                    let decision = await mockSessionClient.passengerAuthDecision(authentication.phone)
                    await send(.passengerAuthDecisionResolved(PassengerAuthRouting(
                        phoneNumber: authentication.phone,
                        decision: decision
                    )))
                }

            case .otp:
                return .none

            case let .passengerAuthDecisionResolved(routing):
                state.applyPassengerAuthDecision(routing)
                return .none

            // Logout -> phone login
            case .passengerApp(.delegate(.loggedOut)):
                try? keychainClient.delete("birge_access_token")
                try? keychainClient.delete("birge_refresh_token")
                try? keychainClient.delete("birge_user_id")
                state = .unauthenticated(OTPFeature.State())
                return .run { _ in
                    await mockSessionClient.clearSession()
                }

            case .passengerApp:
                return .none
            }
        }
        .ifCaseLet(\.splash, action: \.splash) {
            SplashFeature()
        }
        .ifCaseLet(\.needsOnboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifCaseLet(\.unauthenticated, action: \.otp) {
            OTPFeature()
        }
        .ifCaseLet(\.authenticated, action: \.passengerApp) {
            PassengerAppFeature()
        }
    }
}

private extension AppFeature.State {
    mutating func applyPassengerAuthDecision(_ routing: PassengerAuthRouting) {
        switch routing.decision {
        case .phoneLogin:
            self = .unauthenticated(OTPFeature.State())
        case .registration:
            self = .needsOnboarding(OnboardingFeature.State(
                phoneNumber: routing.phoneNumber,
                passengerSetupStep: .profileBasics
            ))
        case let .resumeSetup(step):
            self = .needsOnboarding(OnboardingFeature.State(
                phoneNumber: routing.phoneNumber,
                passengerSetupStep: step
            ))
        case .firstRouteSetup:
            self = .needsOnboarding(OnboardingFeature.State(
                phoneNumber: routing.phoneNumber,
                initialStep: .firstRouteEntry
            ))
        case .subscriptionSelection:
            var passengerState = PassengerAppFeature.State()
            passengerState.path.append(.subscriptions(SubscriptionsFeature.State()))
            self = .authenticated(passengerState)
        case .home:
            self = .authenticated(PassengerAppFeature.State())
        }
    }
}
