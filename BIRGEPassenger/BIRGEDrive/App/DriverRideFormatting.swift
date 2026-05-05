//
//  DriverRideFormatting.swift
//  BIRGEDrive
//

import SwiftUI

enum DriverRideFormatting {
    typealias Ride = DriverAppFeature.DriverActiveRide
    typealias RideStatus = DriverAppFeature.DriverActiveRide.RideStatus

    static func statusText(for status: RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "Едем за пассажиром"
        case .passengerWait:
            return "Ожидаем пассажира"
        case .inProgress:
            return "Поездка началась"
        }
    }

    static func statusSubtitle(for ride: Ride) -> String {
        switch ride.status {
        case .pickingUp:
            return "Точка посадки · \(ride.etaMinutes) мин · 1.2 км"
        case .passengerWait:
            return "Проверьте коды посадки и начните маршрут"
        case .inProgress:
            return "\(ride.destination) · ~\(ride.etaMinutes) мин"
        }
    }

    static func nextManeuverText(for ride: Ride) -> String {
        switch ride.status {
        case .pickingUp:
            return "Поверните направо к точке посадки"
        case .passengerWait:
            return "Остановитесь у входа и проверьте посадку"
        case .inProgress:
            return "Держитесь правее к \(ride.destination)"
        }
    }

    static func nextManeuverDistance(for status: RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "через 450 м"
        case .passengerWait:
            return "через 80 м"
        case .inProgress:
            return "через 1.2 км"
        }
    }

    static func routeGuidanceDetail(for ride: Ride) -> String {
        switch ride.status {
        case .pickingUp:
            return "Финиш подачи: \(ride.pickup)"
        case .passengerWait:
            return "После посадки маршрут продолжится до \(ride.destination)"
        case .inProgress:
            return "Финальная точка: \(ride.destination)"
        }
    }

    static func routePhaseText(for status: RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "Подача"
        case .passengerWait:
            return "Посадка"
        case .inProgress:
            return "В пути"
        }
    }

    static func maneuverSymbol(for status: RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "arrow.turn.up.right"
        case .passengerWait:
            return "parkingsign.circle.fill"
        case .inProgress:
            return "arrow.up.forward.circle.fill"
        }
    }

    static func statusIcon(for status: RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "car.fill"
        case .passengerWait:
            return "mappin.circle.fill"
        case .inProgress:
            return "arrow.triangle.turn.up.right.circle.fill"
        }
    }

    static func progressLabel(for status: RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "Подача"
        case .passengerWait:
            return "Посадка"
        case .inProgress:
            return "Маршрут"
        }
    }

    static func progressValue(for status: RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "35%"
        case .passengerWait:
            return "60%"
        case .inProgress:
            return "72%"
        }
    }

    static func progressAmount(for status: RideStatus) -> CGFloat {
        switch status {
        case .pickingUp:
            return 0.35
        case .passengerWait:
            return 0.60
        case .inProgress:
            return 0.72
        }
    }

    static func actionText(for status: RideStatus) -> String {
        switch status {
        case .pickingUp:
            return "Прибыл к пассажиру"
        case .passengerWait:
            return "Начать поездку"
        case .inProgress:
            return "Завершить поездку"
        }
    }

    static func avatarColor(for initial: String) -> Color {
        switch initial {
        case "М":
            return BIRGEColors.success
        case "Д":
            return BIRGEColors.warning
        default:
            return BIRGEColors.brandPrimary
        }
    }

    static func statusColor(for status: RideStatus) -> Color {
        switch status {
        case .pickingUp, .passengerWait:
            return BIRGEColors.warning
        case .inProgress:
            return BIRGEColors.success
        }
    }
}
