import Foundation
import XCTest
@testable import Arabica

@MainActor
final class SessionMenuModelTests: XCTestCase {
    func testDefaultModeIsSystemOnly() {
        let model = makeModel()

        XCTAssertEqual(model.selectedDisplayOption, .keepDisplayAwake)
        XCTAssertTrue(model.keepsDisplayAwake)
        XCTAssertFalse(model.letsDisplaySleepForNextSession)
    }

    func testInitialPreferencesSeedMenuDefaults() {
        let model = makeModel(
            initialPreferences: AppPreferences(
                quickDurationPreset: .twoHours,
                defaultDisplayOption: .keepDisplayAwake,
                lowBatteryThreshold: 30
            )
        )

        XCTAssertEqual(model.preferredQuickPreset, .twoHours)
        XCTAssertEqual(model.selectedDisplayOption, .keepDisplayAwake)
        XCTAssertEqual(model.lowBatteryThreshold, 30)
    }

    func testSelectingThirtyMinutesStartsTheCorrectRequest() {
        let model = makeModel()

        model.startSession(for: .thirtyMinutes)

        XCTAssertEqual(model.activeSession?.endsAt, Date(timeIntervalSinceReferenceDate: 2_800))
        XCTAssertEqual(model.activeSession?.displayOption, .keepDisplayAwake)
    }

    func testSelectingOneHourStartsTheCorrectRequest() {
        let model = makeModel()

        model.startSession(for: .oneHour)

        XCTAssertEqual(model.activeSession?.endsAt, Date(timeIntervalSinceReferenceDate: 4_600))
        XCTAssertEqual(model.activeSession?.displayOption, .keepDisplayAwake)
    }

    func testSelectingTwoHoursStartsTheCorrectRequest() {
        let model = makeModel()

        model.startSession(for: .twoHours)

        XCTAssertEqual(model.activeSession?.endsAt, Date(timeIntervalSinceReferenceDate: 8_200))
        XCTAssertEqual(model.activeSession?.displayOption, .keepDisplayAwake)
    }

    func testSelectingIndefiniteStartsTheCorrectRequest() {
        let model = makeModel()

        model.startIndefiniteSession()

        XCTAssertNil(model.activeSession?.endsAt)
        XCTAssertEqual(model.activeSession?.displayOption, .keepDisplayAwake)
        XCTAssertTrue(model.hasActiveIndefiniteSession)
    }

    func testTogglingIndefiniteSessionEndsExistingIndefiniteSession() {
        let model = makeModel()

        model.toggleIndefiniteSession()
        XCTAssertTrue(model.hasActiveIndefiniteSession)

        model.toggleIndefiniteSession()

        XCTAssertNil(model.activeSession)
        XCTAssertFalse(model.hasActiveIndefiniteSession)
    }

    func testEndingSessionClearsActiveState() {
        let model = makeModel()
        model.startIndefiniteSession()

        model.endSession()

        XCTAssertNil(model.activeSession)
    }

    func testTogglingLetDisplaySleepChangesTheRequestedAssertionBehaviorForNextSessionOnly() {
        let assertionController = FakeAssertionController()
        let model = makeModel(assertionController: assertionController)

        model.toggleDisplayAwakeSelection()
        model.startIndefiniteSession()

        XCTAssertEqual(model.activeSession?.displayOption, .allowDisplaySleep)
        XCTAssertEqual(assertionController.activations, [.allowDisplaySleep])
        XCTAssertEqual(model.selectedDisplayOption, .keepDisplayAwake)
        XCTAssertTrue(model.keepsDisplayAwake)
        XCTAssertFalse(model.letsDisplaySleepForNextSession)
    }

    func testStartingUntilSessionUsesResolvedEndDateAndSelectedDisplayBehavior() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let model = makeModel(
            initialPreferences: AppPreferences(
                quickDurationPreset: .oneHour,
                defaultDisplayOption: .keepDisplayAwake,
                lowBatteryThreshold: nil
            ),
            calendar: calendar
        )

        model.startUntilSession(UntilTime(hour: 11, minute: 45))

        XCTAssertEqual(
            model.activeSession,
            ActiveSession(
                startedAt: Date(timeIntervalSinceReferenceDate: 1_000),
                endsAt: DateComponents(
                    calendar: calendar,
                    year: 2001,
                    month: 1,
                    day: 1,
                    hour: 11,
                    minute: 45
                ).date!,
                displayOption: .keepDisplayAwake
            )
        )
    }

    func testLowBatteryGuardEndsActiveSessionWhenPowerSourceDropsBelowThreshold() {
        let model = makeModel(
            initialPreferences: AppPreferences(
                quickDurationPreset: .oneHour,
                defaultDisplayOption: .keepDisplayAwake,
                lowBatteryThreshold: 25
            )
        )
        model.startIndefiniteSession()

        model.updatePowerSource(.battery(percentRemaining: 20))

        XCTAssertNil(model.activeSession)
    }

    func testApplyingPreferencesReplacesCurrentPreferences() {
        let model = makeModel()
        let preferences = AppPreferences(
            quickDurationPreset: .twoHours,
            defaultDisplayOption: .keepDisplayAwake,
            lowBatteryThreshold: 30
        )

        model.applyPreferences(preferences)

        XCTAssertEqual(model.currentPreferences, preferences)
        XCTAssertEqual(model.preferredQuickPreset, .twoHours)
        XCTAssertEqual(model.selectedDisplayOption, .keepDisplayAwake)
        XCTAssertEqual(model.lowBatteryThreshold, 30)
    }

    func testDisplayToggleDoesNotPersistIntoPreferences() {
        let model = makeModel()

        model.toggleDisplayAwakeSelection()

        XCTAssertEqual(model.currentPreferences, .default)
        XCTAssertTrue(model.letsDisplaySleepForNextSession)
    }

    private func makeModel(
        assertionController: FakeAssertionController = FakeAssertionController(),
        initialPreferences: AppPreferences = .default,
        calendar: Calendar = .autoupdatingCurrent
    ) -> SessionMenuModel {
        SessionMenuModel(
            clock: FixedClock(now: Date(timeIntervalSinceReferenceDate: 1_000)),
            calendar: calendar,
            assertionController: assertionController,
            timerScheduler: FakeTimerScheduler(),
            initialPreferences: initialPreferences
        )
    }
}

private struct FixedClock: Clock {
    let now: Date
}

private final class FakeAssertionController: AssertionControlling {
    private(set) var activations: [SessionDisplayOption] = []

    func activate(for displayOption: SessionDisplayOption) -> Bool {
        activations.append(displayOption)
        return true
    }

    func deactivate() {}
}

private final class FakeTimerScheduler: TimerScheduling {
    func schedule(at date: Date, _ action: @escaping () -> Void) -> TimerCancellation {
        FakeTimerCancellation()
    }
}

private final class FakeTimerCancellation: TimerCancellation {
    func cancel() {}
}
