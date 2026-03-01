import Foundation

final class UserDefaultsPreferencesStore {
    private enum Key {
        static let quickDurationPreset = "preferences.quickDurationPreset"
        static let defaultDisplayOption = "preferences.defaultDisplayOption"
        static let lowBatteryThreshold = "preferences.lowBatteryThreshold"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> AppPreferences {
        AppPreferences(
            quickDurationPreset: loadValue(forKey: Key.quickDurationPreset, default: AppPreferences.default.quickDurationPreset),
            defaultDisplayOption: loadValue(forKey: Key.defaultDisplayOption, default: AppPreferences.default.defaultDisplayOption),
            lowBatteryThreshold: loadLowBatteryThreshold()
        )
    }

    func save(_ preferences: AppPreferences) {
        userDefaults.set(preferences.quickDurationPreset.rawValue, forKey: Key.quickDurationPreset)
        userDefaults.set(preferences.defaultDisplayOption.rawValue, forKey: Key.defaultDisplayOption)

        if let lowBatteryThreshold = preferences.lowBatteryThreshold {
            userDefaults.set(lowBatteryThreshold, forKey: Key.lowBatteryThreshold)
        } else {
            userDefaults.removeObject(forKey: Key.lowBatteryThreshold)
        }
    }

    private func loadValue<Value: RawRepresentable>(
        forKey key: String,
        default defaultValue: Value
    ) -> Value where Value.RawValue == String {
        guard
            let rawValue = userDefaults.string(forKey: key),
            let value = Value(rawValue: rawValue)
        else {
            return defaultValue
        }

        return value
    }

    private func loadLowBatteryThreshold() -> Int? {
        guard userDefaults.object(forKey: Key.lowBatteryThreshold) != nil else {
            return AppPreferences.default.lowBatteryThreshold
        }

        return userDefaults.integer(forKey: Key.lowBatteryThreshold)
    }
}
