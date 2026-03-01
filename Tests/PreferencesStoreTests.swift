import Foundation
import XCTest
@testable import Arabica

final class PreferencesStoreTests: XCTestCase {
    func testLoadingWithoutSavedValuesReturnsDefaultPreferences() {
        let userDefaults = makeUserDefaults()
        let store = UserDefaultsPreferencesStore(userDefaults: userDefaults)

        XCTAssertEqual(store.load(), .default)
    }

    func testSavingAndRestoringPreferencesRoundTripsValues() {
        let userDefaults = makeUserDefaults()
        let store = UserDefaultsPreferencesStore(userDefaults: userDefaults)
        let preferences = AppPreferences(
            quickDurationPreset: .twoHours,
            defaultDisplayOption: .keepDisplayAwake,
            lowBatteryThreshold: 25
        )

        store.save(preferences)

        XCTAssertEqual(store.load(), preferences)
    }

    func testDefaultQuickSessionRequestUsesPreferredPreset() {
        let preferences = AppPreferences(
            quickDurationPreset: .twoHours,
            defaultDisplayOption: .allowDisplaySleep,
            lowBatteryThreshold: nil
        )

        XCTAssertEqual(
            preferences.defaultQuickSessionRequest(),
            SessionRequest(
                duration: .preset(.twoHours),
                displayOption: .allowDisplaySleep
            )
        )
    }

    func testDefaultQuickSessionRequestUsesPreferredDisplayBehavior() {
        let preferences = AppPreferences(
            quickDurationPreset: .thirtyMinutes,
            defaultDisplayOption: .keepDisplayAwake,
            lowBatteryThreshold: nil
        )

        XCTAssertEqual(
            preferences.defaultQuickSessionRequest(),
            SessionRequest(
                duration: .preset(.thirtyMinutes),
                displayOption: .keepDisplayAwake
            )
        )
    }

    func testLoadingAppliesSavedBatteryThresholdPreference() {
        let userDefaults = makeUserDefaults()
        let store = UserDefaultsPreferencesStore(userDefaults: userDefaults)
        let preferences = AppPreferences(
            quickDurationPreset: .oneHour,
            defaultDisplayOption: .allowDisplaySleep,
            lowBatteryThreshold: 40
        )

        store.save(preferences)

        XCTAssertEqual(store.load().lowBatteryThreshold, 40)
    }

    func testLoadingInvalidQuickDurationPresetFallsBackToDefault() {
        let userDefaults = makeUserDefaults()
        userDefaults.set("invalid", forKey: "preferences.quickDurationPreset")
        let store = UserDefaultsPreferencesStore(userDefaults: userDefaults)

        XCTAssertEqual(store.load().quickDurationPreset, AppPreferences.default.quickDurationPreset)
    }

    func testSavingNilBatteryThresholdRemovesStoredValue() {
        let userDefaults = makeUserDefaults()
        let store = UserDefaultsPreferencesStore(userDefaults: userDefaults)

        store.save(
            AppPreferences(
                quickDurationPreset: .oneHour,
                defaultDisplayOption: .allowDisplaySleep,
                lowBatteryThreshold: 25
            )
        )
        store.save(
            AppPreferences(
                quickDurationPreset: .oneHour,
                defaultDisplayOption: .allowDisplaySleep,
                lowBatteryThreshold: nil
            )
        )

        XCTAssertNil(userDefaults.object(forKey: "preferences.lowBatteryThreshold"))
        XCTAssertNil(store.load().lowBatteryThreshold)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "PreferencesStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        return userDefaults
    }
}
