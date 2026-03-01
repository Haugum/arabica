import Foundation

enum SessionDisplayOption: String, CaseIterable, Hashable {
    case allowDisplaySleep
    case keepDisplayAwake

    var preferencesTitle: String {
        switch self {
        case .allowDisplaySleep:
            return "Allow Display Sleep"
        case .keepDisplayAwake:
            return "Keep Display Awake Too"
        }
    }
}

enum SessionDuration: Equatable {
    case preset(SessionPreset)
    case until(Date)
    case indefinite
}

struct SessionRequest: Equatable {
    let duration: SessionDuration
    let displayOption: SessionDisplayOption

    func activate(at startDate: Date) -> ActiveSession {
        let endDate: Date?

        switch duration {
        case let .preset(preset):
            endDate = startDate.addingTimeInterval(preset.duration)
        case let .until(date):
            endDate = date
        case .indefinite:
            endDate = nil
        }

        return ActiveSession(
            startedAt: startDate,
            endsAt: endDate,
            displayOption: displayOption
        )
    }
}

struct ActiveSession: Equatable {
    let startedAt: Date
    let endsAt: Date?
    let displayOption: SessionDisplayOption

    func hasExpired(at date: Date) -> Bool {
        guard let endsAt else {
            return false
        }

        return date >= endsAt
    }
}
