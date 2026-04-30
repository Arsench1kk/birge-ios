import Vapor

actor WSHub {
    private var connections: [UUID: WebSocket] = [:]

    func connect(id: UUID, socket: WebSocket) {
        connections[id] = socket
    }

    func disconnect(id: UUID) {
        connections[id] = nil
    }

    func broadcast(_ text: String) {
        for socket in connections.values {
            socket.send(text)
        }
    }
}

private struct WSHubKey: StorageKey {
    typealias Value = WSHub
}

extension Application {
    var wsHub: WSHub {
        if let existing = self.storage[WSHubKey.self] {
            return existing
        }

        let hub = WSHub()
        self.storage[WSHubKey.self] = hub
        return hub
    }
}
