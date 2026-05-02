import BIRGECore
import ComposableArchitecture
import Foundation

private enum SearchingCancelID {
    static let webSocket = "SearchingFeature.webSocket"
}

@Reducer struct SearchingFeature {
    @ObservableState
    struct State: Equatable {
        var rideId: String
        var statusText: String = "Ожидаем подтверждение водителя"
        var errorMessage: String?
        var isCancelling: Bool = false

        var wsURL: URL? {
            #if DEBUG
            URL(string: "ws://localhost:8080/ws/ride/\(rideId)")
            #else
            URL(string: "wss://api.birge.kz/ws/ride/\(rideId)")
            #endif
        }
    }

    struct DriverMatch: Equatable, Sendable {
        var driverName: String?
        var driverRating: Double?
        var driverVehicle: String?
        var driverPlate: String?
        var etaSeconds: Int?
    }

    enum Action: ViewAction, Sendable {
        case view(View)
        case webSocketEventReceived(WebSocketEvent)
        case subscribeFailed(String)
        case cancelFailed(String)
        case delegate(Delegate)

        @CasePathable
        enum View: Sendable {
            case onAppear
            case onDisappear
            case cancelTapped
        }

        @CasePathable
        enum Delegate: Sendable {
            case driverFound(rideID: String, DriverMatch)
            case cancelled
        }
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.webSocketClient) var webSocketClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard let url = state.wsURL else {
                    state.errorMessage = "Не удалось открыть соединение."
                    return .none
                }
                return .run { send in
                    let eventStream = await webSocketClient.connect(url)
                    for await event in eventStream {
                        await send(.webSocketEventReceived(event))
                    }
                }
                .cancellable(id: SearchingCancelID.webSocket, cancelInFlight: true)

            case .view(.onDisappear):
                return .merge(
                    .cancel(id: SearchingCancelID.webSocket),
                    .run { _ in
                        await webSocketClient.disconnect()
                    }
                )

            case .view(.cancelTapped):
                state.isCancelling = true
                state.errorMessage = nil
                let rideId = state.rideId
                return .run { send in
                    do {
                        try await apiClient.cancelRide(rideId, "passenger_cancelled")
                        await send(.delegate(.cancelled))
                    } catch {
                        await send(.cancelFailed(error.localizedDescription))
                    }
                }

            case let .webSocketEventReceived(event):
                switch event {
                case .connected:
                    let rideId = state.rideId
                    return .run { send in
                        do {
                            let message = try await Self.subscribeMessage(rideId: rideId)
                            try await webSocketClient.send(.text(message))
                        } catch {
                            await send(.subscribeFailed(error.localizedDescription))
                        }
                    }

                case let .message(.text(json)):
                    guard let match = Self.driverMatch(from: json) else {
                        return .none
                    }
                    return .send(.delegate(.driverFound(rideID: state.rideId, match)))

                case .message(.data):
                    return .none

                case .disconnected:
                    state.statusText = "Восстанавливаем соединение"
                    return .none

                case .error:
                    state.errorMessage = "Нет соединения. Пробуем переподключиться."
                    return .none
                }

            case let .subscribeFailed(message):
                state.errorMessage = message
                return .none

            case let .cancelFailed(message):
                state.isCancelling = false
                state.errorMessage = message
                return .none

            case .delegate:
                state.isCancelling = false
                return .merge(
                    .cancel(id: SearchingCancelID.webSocket),
                    .run { _ in
                        await webSocketClient.disconnect()
                    }
                )
            }
        }
    }

    private static func subscribeMessage(rideId: String) throws -> String {
        let payload = SubscribeMessage(type: "subscribe", channel: "ride/\(rideId)", rideId: rideId)
        let data = try JSONEncoder().encode(payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw WebSocketError.encodingError("Could not encode subscribe message.")
        }
        return text
    }

    private static func driverMatch(from json: String) -> DriverMatch? {
        guard let data = json.data(using: .utf8) else { return nil }

        if let rideEvent = try? JSONDecoder().decode(RideEvent.self, from: data),
           rideEvent.event == RideEvent.EventType.statusChanged,
           rideEvent.payload.status == RideStatus.matched.rawValue {
            return DriverMatch(
                driverName: rideEvent.payload.driverName,
                driverRating: rideEvent.payload.driverRating,
                driverVehicle: rideEvent.payload.driverVehicle,
                driverPlate: rideEvent.payload.driverPlate,
                etaSeconds: rideEvent.payload.etaSeconds
            )
        }

        guard let matchedEvent = try? JSONDecoder().decode(RideMatchedEvent.self, from: data),
              matchedEvent.eventName == "ride_matched" else {
            return nil
        }

        return DriverMatch(
            driverName: matchedEvent.payload.driver?.name ?? matchedEvent.payload.driverName,
            driverRating: matchedEvent.payload.driver?.rating ?? matchedEvent.payload.driverRating,
            driverVehicle: matchedEvent.payload.driver?.vehicle ?? matchedEvent.payload.driverVehicle,
            driverPlate: matchedEvent.payload.driver?.plate ?? matchedEvent.payload.driverPlate,
            etaSeconds: matchedEvent.payload.etaSeconds
        )
    }
}

private struct SubscribeMessage: Encodable {
    let type: String
    let channel: String
    let rideId: String

    private enum CodingKeys: String, CodingKey {
        case type
        case channel
        case rideId = "ride_id"
    }
}

private struct RideMatchedEvent: Decodable {
    let event: String?
    let type: String?
    let payload: Payload

    var eventName: String? {
        event ?? type
    }

    struct Payload: Decodable {
        let driver: Driver?
        let driverName: String?
        let driverRating: Double?
        let driverVehicle: String?
        let driverPlate: String?
        let etaSeconds: Int?

        private enum CodingKeys: String, CodingKey {
            case driver
            case driverName = "driver_name"
            case driverRating = "driver_rating"
            case driverVehicle = "driver_vehicle"
            case driverPlate = "driver_plate"
            case etaSeconds = "eta_seconds"
        }
    }

    struct Driver: Decodable {
        let name: String?
        let rating: Double?
        let vehicle: String?
        let plate: String?
    }
}
