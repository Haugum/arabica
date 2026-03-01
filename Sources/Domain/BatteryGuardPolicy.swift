import Foundation

enum PowerSourceSnapshot: Equatable {
    case ac
    case battery(percentRemaining: Int)
}

enum BatteryGuardAction: Equatable {
    case keepSession
    case endSession
}

struct BatteryGuardPolicy: Equatable {
    let lowBatteryThreshold: Int?

    func action(
        for powerSource: PowerSourceSnapshot,
        activeSession: ActiveSession?
    ) -> BatteryGuardAction {
        guard activeSession != nil else {
            return .keepSession
        }

        guard let lowBatteryThreshold else {
            return .keepSession
        }

        switch powerSource {
        case .ac:
            return .keepSession
        case let .battery(percentRemaining):
            return percentRemaining < lowBatteryThreshold ? .endSession : .keepSession
        }
    }
}
