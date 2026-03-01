import Foundation
import XCTest
@testable import Arabica

final class SessionControllerTests: XCTestCase {
    func testStartingTimedSessionActivatesAssertionAndSchedulesExpiration() {
        let assertionController = FakeAssertionController()
        let timerScheduler = FakeTimerScheduler()
        let controller = SessionController(
            clock: FixedClock(now: Date(timeIntervalSinceReferenceDate: 1_000)),
            assertionController: assertionController,
            timerScheduler: timerScheduler
        )

        controller.start(
            SessionRequest(
                duration: .preset(.thirtyMinutes),
                displayOption: .allowDisplaySleep
            )
        )

        XCTAssertEqual(assertionController.activations, [.allowDisplaySleep])
        XCTAssertEqual(timerScheduler.scheduledDates, [Date(timeIntervalSinceReferenceDate: 2_800)])
        XCTAssertEqual(controller.activeSession?.endsAt, Date(timeIntervalSinceReferenceDate: 2_800))
    }

    func testStartingNewSessionReplacesPreviousSessionAndCancelsOldTimer() {
        let assertionController = FakeAssertionController()
        let timerScheduler = FakeTimerScheduler()
        let controller = SessionController(
            clock: FixedClock(now: Date(timeIntervalSinceReferenceDate: 1_000)),
            assertionController: assertionController,
            timerScheduler: timerScheduler
        )

        controller.start(
            SessionRequest(
                duration: .preset(.thirtyMinutes),
                displayOption: .allowDisplaySleep
            )
        )
        controller.start(
            SessionRequest(
                duration: .indefinite,
                displayOption: .keepDisplayAwake
            )
        )

        XCTAssertEqual(assertionController.deactivationCount, 1)
        XCTAssertEqual(assertionController.activations, [.allowDisplaySleep, .keepDisplayAwake])
        XCTAssertEqual(timerScheduler.cancelCount, 1)
        XCTAssertNil(controller.activeSession?.endsAt)
        XCTAssertEqual(controller.activeSession?.displayOption, .keepDisplayAwake)
    }

    func testEndingSessionClearsActiveSessionAndReleasesAssertion() {
        let assertionController = FakeAssertionController()
        let timerScheduler = FakeTimerScheduler()
        let controller = SessionController(
            clock: FixedClock(now: Date(timeIntervalSinceReferenceDate: 1_000)),
            assertionController: assertionController,
            timerScheduler: timerScheduler
        )

        controller.start(
            SessionRequest(
                duration: .indefinite,
                displayOption: .allowDisplaySleep
            )
        )

        controller.endSession()

        XCTAssertNil(controller.activeSession)
        XCTAssertEqual(assertionController.deactivationCount, 1)
    }

    func testExpirationEndsSessionAutomatically() {
        let assertionController = FakeAssertionController()
        let timerScheduler = FakeTimerScheduler()
        let controller = SessionController(
            clock: FixedClock(now: Date(timeIntervalSinceReferenceDate: 1_000)),
            assertionController: assertionController,
            timerScheduler: timerScheduler
        )

        controller.start(
            SessionRequest(
                duration: .preset(.thirtyMinutes),
                displayOption: .allowDisplaySleep
            )
        )

        timerScheduler.fire()

        XCTAssertNil(controller.activeSession)
        XCTAssertEqual(assertionController.deactivationCount, 1)
    }
}

private struct FixedClock: Clock {
    let now: Date
}

private final class FakeAssertionController: AssertionControlling {
    private(set) var activations: [SessionDisplayOption] = []
    private(set) var deactivationCount = 0

    func activate(for displayOption: SessionDisplayOption) -> Bool {
        activations.append(displayOption)
        return true
    }

    func deactivate() {
        deactivationCount += 1
    }
}

private final class FakeTimerScheduler: TimerScheduling {
    private(set) var scheduledDates: [Date] = []
    private(set) var cancelCount = 0
    private var scheduledAction: (() -> Void)?

    func schedule(at date: Date, _ action: @escaping () -> Void) -> TimerCancellation {
        scheduledDates.append(date)
        scheduledAction = action
        return FakeTimerCancellation { [weak self] in
            self?.cancelCount += 1
            self?.scheduledAction = nil
        }
    }

    func fire() {
        let action = scheduledAction
        scheduledAction = nil
        action?()
    }
}

private final class FakeTimerCancellation: TimerCancellation {
    private let onCancel: () -> Void
    private var isCancelled = false

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        guard !isCancelled else {
            return
        }

        isCancelled = true
        onCancel()
    }
}
