//
//  WebSocketClient+DependencyValues.swift
//  BIRGECore
//
//  Registers WebSocketClient in TCA's DependencyValues.
//  IOS-014 — WebSocketClient TCA Dependency
//

import ComposableArchitecture

extension DependencyValues {
    /// The WebSocket client dependency.
    ///
    /// Access in any Reducer via:
    /// ```swift
    /// @Dependency(\.webSocketClient) var webSocketClient
    /// ```
    public var webSocketClient: WebSocketClient {
        get { self[WebSocketClient.self] }
        set { self[WebSocketClient.self] = newValue }
    }
}
