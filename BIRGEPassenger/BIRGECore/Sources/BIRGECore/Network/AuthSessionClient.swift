import ComposableArchitecture
import Foundation

public enum AuthSessionEvent: Equatable, Sendable {
    case authExpired(message: String)
}

public struct AuthSessionClient: Sendable {
    public var events: @Sendable () -> AsyncStream<AuthSessionEvent>
    public var sendAuthExpired: @Sendable (_ message: String) async -> Void

    public init(
        events: @escaping @Sendable () -> AsyncStream<AuthSessionEvent>,
        sendAuthExpired: @escaping @Sendable (_ message: String) async -> Void
    ) {
        self.events = events
        self.sendAuthExpired = sendAuthExpired
    }
}

extension AuthSessionClient: DependencyKey {
    public static let liveValue = AuthSessionClient(
        events: {
            AsyncStream { continuation in
                let id = UUID()
                Task {
                    await AuthSessionEventHub.shared.add(id: id, continuation: continuation)
                }
                continuation.onTermination = { @Sendable _ in
                    Task {
                        await AuthSessionEventHub.shared.remove(id: id)
                    }
                }
            }
        },
        sendAuthExpired: { message in
            await AuthSessionEventHub.shared.send(.authExpired(message: message))
        }
    )

    public static let testValue = AuthSessionClient(
        events: {
            AsyncStream { continuation in
                continuation.finish()
            }
        },
        sendAuthExpired: { _ in }
    )
}

extension DependencyValues {
    public var authSessionClient: AuthSessionClient {
        get { self[AuthSessionClient.self] }
        set { self[AuthSessionClient.self] = newValue }
    }
}

private actor AuthSessionEventHub {
    static let shared = AuthSessionEventHub()

    private var continuations: [UUID: AsyncStream<AuthSessionEvent>.Continuation] = [:]

    func add(id: UUID, continuation: AsyncStream<AuthSessionEvent>.Continuation) {
        continuations[id] = continuation
    }

    func remove(id: UUID) {
        continuations[id] = nil
    }

    func send(_ event: AuthSessionEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }
}
