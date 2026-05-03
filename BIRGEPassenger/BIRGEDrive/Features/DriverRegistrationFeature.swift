import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct DriverRegistrationFeature {
    @ObservableState
    struct State: Equatable {
        var step: Step = .personal
        var firstName = ""
        var lastName = ""
        var birthDate = ""
        var iin = ""
        var carMake = ""
        var carModel = ""
        var carYear = ""
        var plateNumber = ""
        var selectedColor: CarColor = .white
        var seats = 4
        var uploadedDocuments: Set<DocumentKind> = [.driverLicenseFront]
        var selectedTier: DriverTier = .professional

        var progress: Double {
            Double(step.rawValue + 1) / Double(Step.allCases.count)
        }

        var canGoBack: Bool {
            step != .personal
        }

        enum Step: Int, CaseIterable, Equatable, Sendable {
            case personal
            case vehicle
            case documents
            case tier
        }
    }

    enum Action: Equatable, Sendable {
        case firstNameChanged(String)
        case lastNameChanged(String)
        case birthDateChanged(String)
        case iinChanged(String)
        case carMakeChanged(String)
        case carModelChanged(String)
        case carYearChanged(String)
        case plateNumberChanged(String)
        case colorSelected(CarColor)
        case seatsSelected(Int)
        case documentTapped(DocumentKind)
        case tierSelected(DriverTier)
        case backTapped
        case nextTapped
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            case completed
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .firstNameChanged(let value):
                state.firstName = value
                return .none
            case .lastNameChanged(let value):
                state.lastName = value
                return .none
            case .birthDateChanged(let value):
                state.birthDate = value
                return .none
            case .iinChanged(let value):
                state.iin = String(value.filter(\.isNumber).prefix(12))
                return .none
            case .carMakeChanged(let value):
                state.carMake = value
                return .none
            case .carModelChanged(let value):
                state.carModel = value
                return .none
            case .carYearChanged(let value):
                state.carYear = String(value.filter(\.isNumber).prefix(4))
                return .none
            case .plateNumberChanged(let value):
                state.plateNumber = value.uppercased()
                return .none
            case .colorSelected(let color):
                state.selectedColor = color
                return .none
            case .seatsSelected(let seats):
                state.seats = seats
                return .none
            case .documentTapped(let document):
                if state.uploadedDocuments.contains(document) {
                    state.uploadedDocuments.remove(document)
                } else {
                    state.uploadedDocuments.insert(document)
                }
                return .none
            case .tierSelected(let tier):
                state.selectedTier = tier
                return .none
            case .backTapped:
                guard state.step.rawValue > 0,
                      let previous = State.Step(rawValue: state.step.rawValue - 1) else {
                    return .none
                }
                state.step = previous
                return .none
            case .nextTapped:
                if let next = State.Step(rawValue: state.step.rawValue + 1) {
                    state.step = next
                    return .none
                }
                return .send(.delegate(.completed))
            case .delegate:
                return .none
            }
        }
    }
}

enum CarColor: String, CaseIterable, Equatable, Sendable {
    case white = "Белый"
    case black = "Чёрный"
    case red = "Красный"
    case blue = "Синий"
    case green = "Зелёный"
    case gray = "Серый"

    var color: Color {
        switch self {
        case .white: return .white
        case .black: return .black
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .gray: return .gray
        }
    }
}

enum DocumentKind: String, CaseIterable, Equatable, Hashable, Sendable {
    case driverLicenseFront = "Права: лицевая"
    case driverLicenseBack = "Права: обратная"
    case vehicleRegistration = "Техпаспорт"
    case identityCard = "Удостоверение"

    var symbol: String {
        switch self {
        case .driverLicenseFront, .driverLicenseBack: return "doc.text.fill"
        case .vehicleRegistration: return "car.fill"
        case .identityCard: return "person.text.rectangle.fill"
        }
    }
}

enum DriverTier: String, CaseIterable, Equatable, Sendable {
    case starter = "Стартер"
    case professional = "Профессионал"
    case premium = "Премиум"

    var price: String {
        switch self {
        case .starter: return "4 900₸ / мес"
        case .professional: return "8 900₸ / мес"
        case .premium: return "14 900₸ / мес"
        }
    }

    var subtitle: String {
        switch self {
        case .starter: return "Для первых коридоров"
        case .professional: return "Лучший баланс для полной смены"
        case .premium: return "Максимальный приоритет"
        }
    }

    var features: [String] {
        switch self {
        case .starter:
            return ["До 30 коридоров", "Стандартная поддержка", "Гарантия дохода 90 дней"]
        case .professional:
            return ["Безлимит коридоров", "Высокий приоритет", "Поддержка 24/7", "Аналитика смен"]
        case .premium:
            return ["Всё из Профессионала", "Персональный менеджер", "Эксклюзивные маршруты"]
        }
    }
}
