import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class ProjectDemoFeatureTests: XCTestCase {
    func testOnAppearLoadsDemoState() async {
        let sample = DemoStateResponse.sample()
        let store = TestStore(initialState: ProjectDemoFeature.State()) {
            ProjectDemoFeature()
        } withDependencies: {
            $0.apiClient = APIClient(fetchDemoState: { sample })
        }

        await store.send(.view(.onAppear)) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.demoStateResponse.success, sample) {
            $0.demoState = sample
            $0.isLoading = false
            $0.errorMessage = nil
        }
    }

    func testSeedDemoDataUpdatesState() async {
        let sample = DemoStateResponse.sample()
        let store = TestStore(initialState: ProjectDemoFeature.State()) {
            ProjectDemoFeature()
        } withDependencies: {
            $0.apiClient = APIClient(seedDemoData: { sample })
        }

        await store.send(.view(.seedTapped)) {
            $0.isMutating = true
            $0.errorMessage = nil
        }

        await store.receive(\.mutationResponse.success, sample) {
            $0.demoState = sample
            $0.isMutating = false
            $0.errorMessage = nil
        }
    }
}
