//
//  LocationClient+DependencyValues.swift
//  BIRGECore
//
//  Registers LocationClient in TCA's DependencyValues.
//  IOS-015 — LocationClient TCA Dependency
//

import ComposableArchitecture

extension DependencyValues {
    /// Access the `LocationClient` dependency in a Reducer.
    ///
    /// ```swift
    /// @Dependency(\.locationClient) var locationClient
    /// ```
    public var locationClient: LocationClient {
        get { self[LocationClient.self] }
        set { self[LocationClient.self] = newValue }
    }
}
