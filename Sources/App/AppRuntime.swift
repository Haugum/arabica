import Foundation

@MainActor
final class AppRuntime {
    private let preferencesStore: UserDefaultsPreferencesStore
    private let powerSourceMonitor: PowerSourceMonitor

    private let sessionMenuModel: SessionMenuModel
    private lazy var statusMenuController = StatusMenuController(model: sessionMenuModel)

    init(
        clock: Clock = SystemClock(),
        calendar: Calendar = .autoupdatingCurrent,
        assertionController: AssertionControlling = IOKitAssertionController(),
        timerScheduler: TimerScheduling = RunLoopTimerScheduler(),
        preferencesStore: UserDefaultsPreferencesStore = UserDefaultsPreferencesStore(),
        powerSourceMonitor: PowerSourceMonitor = PowerSourceMonitor()
    ) {
        self.preferencesStore = preferencesStore
        self.powerSourceMonitor = powerSourceMonitor

        let initialPreferences = preferencesStore.load()

        let sessionMenuModel = SessionMenuModel(
            clock: clock,
            calendar: calendar,
            assertionController: assertionController,
            timerScheduler: timerScheduler,
            initialPreferences: initialPreferences
        )

        self.sessionMenuModel = sessionMenuModel

        powerSourceMonitor.onChange = { [weak sessionMenuModel] snapshot in
            sessionMenuModel?.updatePowerSource(snapshot)
        }
    }

    func start() {
        powerSourceMonitor.start()
        statusMenuController.start()
    }
}
