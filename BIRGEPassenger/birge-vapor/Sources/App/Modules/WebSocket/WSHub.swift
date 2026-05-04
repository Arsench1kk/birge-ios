import Vapor

actor WSHub {
    private struct Connection {
        let channel: String
        let socket: WebSocket
    }

    private var connections: [UUID: Connection] = [:]

    func connect(id: UUID, channel: String, socket: WebSocket) {
        connections[id] = Connection(channel: channel, socket: socket)
    }

    func disconnect(id: UUID) {
        connections[id] = nil
    }

    func broadcast(to channel: String, text: String) {
        for connection in connections.values where connection.channel == channel {
            connection.socket.eventLoop.execute {
                connection.socket.send(text)
            }
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
