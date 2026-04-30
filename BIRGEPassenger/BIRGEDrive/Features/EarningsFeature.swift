//
//  EarningsFeature.swift
//  BIRGEDrive
//

import ComposableArchitecture
import Foundation

// MARK: - Mock Ride Record

struct RideRecord: Equatable, Identifiable, Sendable {
    var id: UUID
    var time: String
    var route: String
    var fare: Int
}

// MARK: - EarningsFeature

@Reducer
struct EarningsFeature {

    @ObservableState
    struct State: Equatable {
        var todayTenge: Int
        var todayRides: Int
        var weekTenge: Int

        var mockRides: [RideRecord] = [
            RideRecord(id: UUID(), time: "09:14", route: "Алатау → Есентай Молл", fare: 1850),
            RideRecord(id: UUID(), time: "10:52", route: "Достык → Аэропорт", fare: 2400),
            RideRecord(id: UUID(), time: "13:30", route: "Байконур → Атакент", fare: 1100),
            RideRecord(id: UUID(), time: "15:45", route: "Сейфуллина → Мега", fare: 950),
        ]
    }

    enum Action: Sendable {
        case onAppear
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
