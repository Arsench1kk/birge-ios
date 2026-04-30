## Swift 6 Strict Concurrency
- All types crossing concurrency boundaries must be Sendable
- @MainActor only on UI types — never on repositories, services
- actor for stateful services (LocationService, DatabaseManager)
- No @unchecked Sendable as a shortcut
