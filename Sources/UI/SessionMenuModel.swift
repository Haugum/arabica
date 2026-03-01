import Foundation

@MainActor
final class SessionMenuModel {
    var onChange: (() -> Void)?

    private static let defaultStartDisplayOption: SessionDisplayOption = .keepDisplayAwake

    private let clock: Clock
    private let calendar: Calendar
    private let timeFormatter: DateFormatter
    private let sessionController: SessionController

    private var preferences: AppPreferences
    private var currentPowerSource: PowerSourceSnapshot = .ac
    private var nextSessionDisplayOption: SessionDisplayOption = .keepDisplayAwake

    var activeSession: ActiveSession? {
        sessionController.activeSession
    }

    var hasActiveIndefiniteSession: Bool {
        activeSession?.endsAt == nil && activeSession != nil
    }

    var keepsDisplayAwake: Bool {
        nextSessionDisplayOption == .keepDisplayAwake
    }

    var letsDisplaySleepForNextSession: Bool {
        nextSessionDisplayOption == .allowDisplaySleep
    }

    var preferredQuickPreset: SessionPreset {
        preferences.quickDurationPreset
    }

    var selectedDisplayOption: SessionDisplayOption {
        nextSessionDisplayOption
    }

    var lowBatteryThreshold: Int? {
        preferences.lowBatteryThreshold
    }

    init(
        clock: Clock,
        calendar: Calendar = .autoupdatingCurrent,
        assertionController: AssertionControlling,
        timerScheduler: TimerScheduling,
        initialPreferences: AppPreferences = .default,
        timeFormatter: DateFormatter = SessionMenuText.makeEndsAtTimeFormatter()
    ) {
        self.clock = clock
        self.calendar = calendar
        self.timeFormatter = timeFormatter
        preferences = initialPreferences
        nextSessionDisplayOption = Self.defaultStartDisplayOption

        let notifyingTimerScheduler = NotifyingTimerScheduler(base: timerScheduler)

        sessionController = SessionController(
            clock: clock,
            assertionController: assertionController,
            timerScheduler: notifyingTimerScheduler
        )

        notifyingTimerScheduler.onFire = { [weak self] in
            self?.notifyChange()
        }
    }

    var menuContent: StatusMenuContent {
        StatusMenuContent.make(
            activeSession: activeSession,
            nextSessionDisplayOption: selectedDisplayOption,
            now: clock.now,
            formatter: timeFormatter
        )
    }

    var currentPreferences: AppPreferences {
        preferences
    }

    func startIndefiniteSession() {
        startAndResetDisplaySelection(
            SessionRequest(
                duration: .indefinite,
                displayOption: selectedDisplayOption
            )
        )
    }

    func toggleIndefiniteSession() {
        if hasActiveIndefiniteSession {
            endSession()
        } else {
            startIndefiniteSession()
        }
    }

    func startSession(for preset: SessionPreset) {
        startAndResetDisplaySelection(
            SessionRequest(
                duration: .preset(preset),
                displayOption: selectedDisplayOption
            )
        )
    }

    func startUntilSession(_ untilTime: UntilTime) {
        startAndResetDisplaySelection(
            SessionRequest.until(
                untilTime,
                relativeTo: clock.now,
                displayOption: selectedDisplayOption,
                calendar: calendar
            )
        )
    }

    func toggleDisplayAwakeSelection() {
        nextSessionDisplayOption = keepsDisplayAwake ? .allowDisplaySleep : .keepDisplayAwake
        notifyChange()
    }

    func applyPreferences(_ preferences: AppPreferences) {
        self.preferences = preferences
        evaluateBatteryGuard()
        notifyChange()
    }

    func updatePowerSource(_ powerSource: PowerSourceSnapshot) {
        currentPowerSource = powerSource
        evaluateBatteryGuard()
        notifyChange()
    }

    func endSession() {
        sessionController.endSession()
        notifyChange()
    }

    private func startAndResetDisplaySelection(_ request: SessionRequest) {
        sessionController.start(request)
        nextSessionDisplayOption = Self.defaultStartDisplayOption
        notifyChange()
    }

    private func evaluateBatteryGuard() {
        let action = BatteryGuardPolicy(lowBatteryThreshold: lowBatteryThreshold).action(
            for: currentPowerSource,
            activeSession: activeSession
        )

        guard action == .endSession else {
            return
        }

        sessionController.endSession()
    }

    private func notifyChange() {
        onChange?()
    }
}

private final class NotifyingTimerScheduler: TimerScheduling {
    private let base: TimerScheduling

    var onFire: () -> Void = {}

    init(base: TimerScheduling) {
        self.base = base
    }

    func schedule(at date: Date, _ action: @escaping () -> Void) -> TimerCancellation {
        base.schedule(at: date) { [onFire] in
            action()
            onFire()
        }
    }
}
