import Foundation

enum SessionPreset: String, CaseIterable, Hashable {
    case thirtyMinutes
    case oneHour
    case twoHours

    var duration: TimeInterval {
        switch self {
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .twoHours:
            return 2 * 60 * 60
        }
    }

    var menuTitle: String {
        switch self {
        case .thirtyMinutes:
            return "Keep Mac Awake for 30 Minutes"
        case .oneHour:
            return "Keep Mac Awake for 1 Hour"
        case .twoHours:
            return "Keep Mac Awake for 2 Hours"
        }
    }

    var shortTitle: String {
        switch self {
        case .thirtyMinutes:
            return "30 Minutes"
        case .oneHour:
            return "1 Hour"
        case .twoHours:
            return "2 Hours"
        }
    }
}
