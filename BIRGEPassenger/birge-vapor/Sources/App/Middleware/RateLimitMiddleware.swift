import Vapor

actor RateLimitStore {
    private var buckets: [String: [Date]] = [:]

    func allows(key: String, limit: Int, window: TimeInterval, now: Date = Date()) -> Bool {
        let cutoff = now.addingTimeInterval(-window)
        var timestamps = buckets[key, default: []].filter { $0 >= cutoff }

        guard timestamps.count < limit else {
            buckets[key] = timestamps
            return false
        }

        timestamps.append(now)
        buckets[key] = timestamps
        return true
    }
}

private struct RateLimitStoreKey: StorageKey {
    typealias Value = RateLimitStore
}

extension Application {
    var rateLimitStore: RateLimitStore {
        if let existing = self.storage[RateLimitStoreKey.self] {
            return existing
        }

        let store = RateLimitStore()
        self.storage[RateLimitStoreKey.self] = store
        return store
    }
}

struct RateLimitMiddleware: AsyncMiddleware {
    let limit: Int
    let window: TimeInterval

    init(limit: Int = 10, window: TimeInterval = 60) {
        self.limit = limit
        self.window = window
    }

    func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let clientIP = req.headers.first(name: "X-Forwarded-For")
            ?? req.remoteAddress?.ipAddress
            ?? "unknown"
        let key = "\(clientIP):\(req.url.path)"

        guard await req.application.rateLimitStore.allows(
            key: key,
            limit: limit,
            window: window
        ) else {
            throw Abort(.tooManyRequests, reason: "Rate limit exceeded")
        }

        return try await next.respond(to: req)
    }
}
