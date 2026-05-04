import Vapor

struct DemoStateDTO: Content, Equatable {
    let generatedAt: Date
    let apiBaseURL: String
    let tables: [DemoTableSnapshotDTO]
    let redis: DemoRedisSnapshotDTO
    let ai: DemoAISnapshotDTO
}

struct DemoTableSnapshotDTO: Content, Equatable {
    let name: String
    let count: Int
    let explanation: String
    let source: String
    let rows: [DemoTableRowDTO]
}

struct DemoTableRowDTO: Content, Equatable {
    let primary: String
    let secondary: String
    let fields: [DemoFieldDTO]
}

struct DemoFieldDTO: Content, Equatable {
    let key: String
    let value: String
}

struct DemoRedisSnapshotDTO: Content, Equatable {
    let dbSize: Int?
    let otpKeys: Int?
    let refreshKeys: Int?
    let blacklistKeys: Int?
    let notes: [String]
}

struct DemoAISnapshotDTO: Content, Equatable {
    let title: String
    let engine: String
    let input: [DemoFieldDTO]
    let scoring: [DemoFieldDTO]
    let candidates: [DemoAICandidateDTO]
    let explanation: String
}

struct DemoAICandidateDTO: Content, Equatable {
    let id: String
    let route: String
    let matchPercent: Int
    let priceTenge: Int
    let seatsLeft: Int
    let reason: String
}
