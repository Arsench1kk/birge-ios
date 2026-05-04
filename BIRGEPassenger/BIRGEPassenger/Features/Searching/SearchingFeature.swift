import BIRGECore
import ComposableArchitecture
import Foundation
import os.log

nonisolated(unsafe) private let searchLog = Logger(
    subsystem: "kz.birge.passenger",
    category: "Searching"
)

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
        var isConnectionLost: Bool = false
    }

    struct DriverInfo: Equatable, Sendable {
        var driverId: String?
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
            case rideMatched(rideID: String, DriverInfo)
            case cancelled
        }
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.keychainClient) var keychainClient
    @Dependency(\.webSocketClient) var webSocketClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                let rideId = state.rideId
                let accessTokenKey = KeychainClient.Keys.accessToken
                let apiClient = self.apiClient
                let keychainClient = self.keychainClient
                let webSocketClient = self.webSocketClient
                return .run { send in
                    let token = try await Self.webSocketAccessToken(
                        apiClient: apiClient,
                        keychainClient: keychainClient,
                        accessTokenKey: accessTokenKey
                    )
                    guard let token else {
                        searchLog.error("[Search] no access token in keychain")
                        await send(.subscribeFailed("Не удалось авторизовать WebSocket."))
                        return
                    }

                    searchLog.info("[Search] token loaded (\(token.prefix(8), privacy: .public)...) for ride \(rideId, privacy: .public)")

                    let url = try Self.webSocketURL(rideId: rideId, token: token)
                    searchLog.info("[Search] connecting to WS for ride \(rideId, privacy: .public)")

                    let eventStream = await webSocketClient.connect(url)
                    for await event in eventStream {
                        searchLog.info("[Search] WS event: \(String(describing: event), privacy: .public)")
                        await send(.webSocketEventReceived(event))
                    }
                    searchLog.info("[Search] WS event stream ended")
                } catch: { error, send in
                    searchLog.error("[Search] WS stream error: \(error.localizedDescription, privacy: .public)")
                    await send(.subscribeFailed(error.localizedDescription))
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
                    searchLog.info("[Search] WS connected — sending subscribe")
                    state.statusText = "Ожидаем подтверждение водителя"
                    state.errorMessage = nil
                    state.isConnectionLost = false
                    let rideId = state.rideId
                    let webSocketClient = self.webSocketClient
                    return .run { send in
                        do {
                            let message = try Self.subscribeMessage(rideId: rideId)
                            try await webSocketClient.send(.text(message))
                            searchLog.info("[Search] subscribe message sent")
                        } catch {
                            searchLog.error("[Search] subscribe send failed: \(error.localizedDescription, privacy: .public)")
                            await send(.subscribeFailed(error.localizedDescription))
                        }
                    }

                case let .message(.text(json)):
                    // Backend sends {"type":"connected"} and {"type":"subscribed"}
                    // as control frames — skip them and wait for ride events.
                    if Self.isControlMessage(json) {
                        searchLog.info("[Search] control message: \(json.prefix(100), privacy: .public)")
                        return .none
                    }

                    guard let driverInfo = Self.driverInfo(from: json) else {
                        searchLog.info("[Search] unrecognized message: \(json.prefix(200), privacy: .public)")
                        return .none
                    }
                    searchLog.info("[Search] ride matched! driver=\(driverInfo.driverName ?? "?", privacy: .public)")
                    return .send(.delegate(.rideMatched(rideID: state.rideId, driverInfo)))

                case .message(.data):
                    return .none

                case .disconnected:
                    searchLog.warning("[Search] WS disconnected")
                    state.statusText = "Восстанавливаем соединение"
                    state.isConnectionLost = true
                    state.errorMessage = "Нет соединения. Пробуем переподключиться."
                    return .none

                case let .error(wsError):
                    let desc = String(describing: wsError)
                    searchLog.error("[Search] WS error: \(desc, privacy: .public)")
                    state.isConnectionLost = true
                    if wsError == .maxRetriesExceeded {
                        state.errorMessage = "Нет соединения."
                    } else {
                        state.errorMessage = "Нет соединения. Пробуем переподключиться."
                    }
                    return .none
                }

            case let .subscribeFailed(message):
                state.errorMessage = message
                state.isConnectionLost = true
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

    nonisolated private static func subscribeMessage(rideId: String) throws -> String {
        let payload = [
            "type": "subscribe",
            "channel": "ride/\(rideId)",
            "ride_id": rideId
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw WebSocketError.encodingError("Could not encode subscribe message.")
        }
        return text
    }

    nonisolated private static func webSocketURL(rideId: String, token: String) throws -> URL {
        var components = URLComponents()
        #if DEBUG
        components.scheme = "ws"
        components.host = "localhost"
        components.port = 8080
        #else
        components.scheme = "wss"
        components.host = "api.birge.kz"
        #endif
        components.path = "/ws/ride/\(rideId)"
        components.queryItems = [
            URLQueryItem(name: "token", value: token)
        ]

        guard let url = components.url else {
            throw WebSocketError.encodingError("Could not build WebSocket URL.")
        }
        return url
    }

    private static func driverInfo(from json: String) -> DriverInfo? {
        guard let data = json.data(using: .utf8) else { return nil }

        if let rideEvent = try? JSONDecoder().decode(RideEvent.self, from: data),
           rideEvent.event == RideEvent.EventType.statusChanged,
           Self.isMatchedStatus(rideEvent.payload.status) {
            return DriverInfo(
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

        return matchedEvent.driverInfo
    }

    private static func isMatchedStatus(_ status: String?) -> Bool {
        status == RideStatus.matched.rawValue || status == "driver_accepted"
    }

    /// Returns true if the JSON is a backend control frame like
    /// {"type":"connected",...} or {"type":"subscribed",...}
    nonisolated private static func isControlMessage(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = dict["type"] as? String
        else { return false }
        return type == "connected" || type == "subscribed"
    }

    nonisolated private static func webSocketAccessToken(
        apiClient: APIClient,
        keychainClient: KeychainClient,
        accessTokenKey: String
    ) async throws -> String? {
        do {
            return try await apiClient.refreshAccessToken()
        } catch {
            searchLog.warning("[Search] access token refresh failed before WS: \(error.localizedDescription, privacy: .public)")
            return try keychainClient.load(accessTokenKey)
        }
    }
}

private struct RideMatchedEvent: Decodable {
    let event: String?
    let type: String?
    let payload: Payload?
    let driverId: String?
    let driverName: String?
    let driverRating: Double?
    let vehiclePlate: String?
    let vehicleModel: String?
    let estimatedArrival: Int?

    var eventName: String? {
        event ?? type
    }

    var driverInfo: SearchingFeature.DriverInfo {
        let etaSeconds = payload?.etaSeconds
            ?? payload?.estimatedArrival.map { $0 * 60 }
            ?? estimatedArrival.map { $0 * 60 }

        return SearchingFeature.DriverInfo(
            driverId: driverId ?? payload?.driverId,
            driverName: payload?.driver?.name ?? payload?.driverName ?? driverName,
            driverRating: payload?.driver?.rating ?? payload?.driverRating ?? driverRating,
            driverVehicle: payload?.driver?.vehicle ?? payload?.driverVehicle ?? payload?.vehicleModel ?? vehicleModel,
            driverPlate: payload?.driver?.plate ?? payload?.driverPlate ?? payload?.vehiclePlate ?? vehiclePlate,
            etaSeconds: etaSeconds
        )
    }

    private enum CodingKeys: String, CodingKey {
        case event
        case type
        case payload
        case driverId
        case driverID = "driver_id"
        case driverName
        case driverNameSnake = "driver_name"
        case driverRating
        case driverRatingSnake = "driver_rating"
        case vehiclePlate
        case vehiclePlateSnake = "vehicle_plate"
        case vehicleModel
        case vehicleModelSnake = "vehicle_model"
        case estimatedArrival
        case estimatedArrivalSnake = "estimated_arrival"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.event = try container.decodeIfPresent(String.self, forKey: .event)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.payload = try container.decodeIfPresent(Payload.self, forKey: .payload)
        self.driverId = try container.decodeIfPresent(String.self, forKey: .driverId)
            ?? container.decodeIfPresent(String.self, forKey: .driverID)
        self.driverName = try container.decodeIfPresent(String.self, forKey: .driverName)
            ?? container.decodeIfPresent(String.self, forKey: .driverNameSnake)
        self.driverRating = try container.decodeIfPresent(Double.self, forKey: .driverRating)
            ?? container.decodeIfPresent(Double.self, forKey: .driverRatingSnake)
        self.vehiclePlate = try container.decodeIfPresent(String.self, forKey: .vehiclePlate)
            ?? container.decodeIfPresent(String.self, forKey: .vehiclePlateSnake)
        self.vehicleModel = try container.decodeIfPresent(String.self, forKey: .vehicleModel)
            ?? container.decodeIfPresent(String.self, forKey: .vehicleModelSnake)
        self.estimatedArrival = try container.decodeIfPresent(Int.self, forKey: .estimatedArrival)
            ?? container.decodeIfPresent(Int.self, forKey: .estimatedArrivalSnake)
    }

    struct Payload: Decodable {
        let driver: Driver?
        let driverId: String?
        let driverName: String?
        let driverRating: Double?
        let driverVehicle: String?
        let driverPlate: String?
        let vehicleModel: String?
        let vehiclePlate: String?
        let estimatedArrival: Int?
        let etaSeconds: Int?

        private enum CodingKeys: String, CodingKey {
            case driver
            case driverId
            case driverID = "driver_id"
            case driverName = "driver_name"
            case driverRating = "driver_rating"
            case driverVehicle = "driver_vehicle"
            case driverPlate = "driver_plate"
            case vehicleModel
            case vehicleModelSnake = "vehicle_model"
            case vehiclePlate
            case vehiclePlateSnake = "vehicle_plate"
            case estimatedArrival
            case estimatedArrivalSnake = "estimated_arrival"
            case etaSeconds = "eta_seconds"
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.driver = try container.decodeIfPresent(Driver.self, forKey: .driver)
            self.driverId = try container.decodeIfPresent(String.self, forKey: .driverId)
                ?? container.decodeIfPresent(String.self, forKey: .driverID)
            self.driverName = try container.decodeIfPresent(String.self, forKey: .driverName)
            self.driverRating = try container.decodeIfPresent(Double.self, forKey: .driverRating)
            self.driverVehicle = try container.decodeIfPresent(String.self, forKey: .driverVehicle)
            self.driverPlate = try container.decodeIfPresent(String.self, forKey: .driverPlate)
            self.vehicleModel = try container.decodeIfPresent(String.self, forKey: .vehicleModel)
                ?? container.decodeIfPresent(String.self, forKey: .vehicleModelSnake)
            self.vehiclePlate = try container.decodeIfPresent(String.self, forKey: .vehiclePlate)
                ?? container.decodeIfPresent(String.self, forKey: .vehiclePlateSnake)
            self.estimatedArrival = try container.decodeIfPresent(Int.self, forKey: .estimatedArrival)
                ?? container.decodeIfPresent(Int.self, forKey: .estimatedArrivalSnake)
            self.etaSeconds = try container.decodeIfPresent(Int.self, forKey: .etaSeconds)
        }
    }

    struct Driver: Decodable {
        let name: String?
        let rating: Double?
        let vehicle: String?
        let plate: String?
    }
}
