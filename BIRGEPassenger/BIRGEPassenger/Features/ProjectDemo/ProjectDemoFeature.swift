import BIRGECore
import ComposableArchitecture
import Foundation

@Reducer
struct ProjectDemoFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: DemoTab = .overview
        var demoState: DemoStateResponse?
        var isLoading = false
        var isMutating = false
        var errorMessage: String?
    }

    enum DemoTab: String, CaseIterable, Identifiable, Sendable {
        case overview
        case database
        case live
        case ai

        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview: return "Обзор"
            case .database: return "База"
            case .live: return "Live"
            case .ai: return "AI"
            }
        }

        var symbol: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .database: return "server.rack"
            case .live: return "dot.radiowaves.left.and.right"
            case .ai: return "sparkles"
            }
        }
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case demoStateResponse(Result<DemoStateResponse, ProjectDemoError>)
        case mutationResponse(Result<DemoStateResponse, ProjectDemoError>)

        @CasePathable
        enum View: Sendable {
            case onAppear
            case refreshTapped
            case seedTapped
            case resetTapped
            case tabSelected(DemoTab)
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard state.demoState == nil else { return .none }
                return loadState(state: &state)

            case .view(.refreshTapped):
                return loadState(state: &state)

            case .view(.seedTapped):
                state.isMutating = true
                state.errorMessage = nil
                let apiClient = self.apiClient
                return .run { send in
                    do {
                        await send(.mutationResponse(.success(try await apiClient.seedDemoData())))
                    } catch {
                        await send(.mutationResponse(.failure(ProjectDemoError(error))))
                    }
                }

            case .view(.resetTapped):
                state.isMutating = true
                state.errorMessage = nil
                let apiClient = self.apiClient
                return .run { send in
                    do {
                        await send(.mutationResponse(.success(try await apiClient.resetDemoData())))
                    } catch {
                        await send(.mutationResponse(.failure(ProjectDemoError(error))))
                    }
                }

            case .view(.tabSelected(let tab)):
                state.selectedTab = tab
                return .none

            case .demoStateResponse(.success(let response)):
                state.demoState = response
                state.isLoading = false
                state.errorMessage = nil
                return .none

            case .demoStateResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.message
                return .none

            case .mutationResponse(.success(let response)):
                state.demoState = response
                state.isMutating = false
                state.errorMessage = nil
                return .none

            case .mutationResponse(.failure(let error)):
                state.isMutating = false
                state.errorMessage = error.message
                return .none
            }
        }
    }

    private func loadState(state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let apiClient = self.apiClient
        return .run { send in
            do {
                await send(.demoStateResponse(.success(try await apiClient.fetchDemoState())))
            } catch {
                await send(.demoStateResponse(.failure(ProjectDemoError(error))))
            }
        }
    }
}

struct ProjectDemoError: Error, Equatable, Sendable {
    let message: String

    init(_ error: any Error) {
        self.message = error.localizedDescription
    }
}
