import Vapor

actor WSHub {
    private struct Connection {
        let channel: String
        let socket: WebSocket
        let sessionID: String?
        let tokenID: String
    }

    private var connections: [UUID: Connection] = [:]

    func connect(id: UUID, channel: String, socket: WebSocket, sessionID: String?, tokenID: String) {
        connections[id] = Connection(channel: channel, socket: socket, sessionID: sessionID, tokenID: tokenID)
    }

    func revoke(sessionID: String?, tokenID: String) {
        let matches = connections.filter { _, connection in
            connection.tokenID == tokenID || (sessionID != nil && connection.sessionID == sessionID)
        }
        for (id, connection) in matches {
            connections[id] = nil
            connection.socket.eventLoop.execute { connection.socket.close(promise: nil) }
        }
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
