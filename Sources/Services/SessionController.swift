import Foundation

protocol Clock {
    var now: Date { get }
}

protocol AssertionControlling {
    @discardableResult
    func activate(for displayOption: SessionDisplayOption) -> Bool
    func deactivate()
}

protocol TimerCancellation {
    func cancel()
}

protocol TimerScheduling {
    func schedule(at date: Date, _ action: @escaping () -> Void) -> TimerCancellation
}

struct SystemClock: Clock {
    var now: Date {
        Date()
    }
}

final class SessionController {
    private let clock: Clock
    private let assertionController: AssertionControlling
    private let timerScheduler: TimerScheduling
    private var expirationTimer: TimerCancellation?

    var onStateChange: ((ActiveSession?) -> Void)?
    private(set) var activeSession: ActiveSession?

    init(
        clock: Clock,
        assertionController: AssertionControlling,
        timerScheduler: TimerScheduling
    ) {
        self.clock = clock
        self.assertionController = assertionController
        self.timerScheduler = timerScheduler
    }

    @discardableResult
    func start(_ request: SessionRequest) -> Bool {
        clearCurrentSession()

        let session = request.activate(at: clock.now)
        guard !session.hasExpired(at: clock.now) else {
            return false
        }

        guard assertionController.activate(for: session.displayOption) else {
            return false
        }

        activeSession = session
        onStateChange?(activeSession)

        if let endsAt = session.endsAt {
            expirationTimer = timerScheduler.schedule(at: endsAt) { [weak self] in
                self?.endSession()
            }
        }

        return true
    }

    @discardableResult
    func updateDisplayOption(_ displayOption: SessionDisplayOption) -> Bool {
        guard let activeSession else {
            return true
        }

        guard activeSession.displayOption != displayOption else {
            return true
        }

        assertionController.deactivate()

        guard assertionController.activate(for: displayOption) else {
            expirationTimer?.cancel()
            expirationTimer = nil
            self.activeSession = nil
            onStateChange?(self.activeSession)
            return false
        }

        self.activeSession = ActiveSession(
            startedAt: activeSession.startedAt,
            endsAt: activeSession.endsAt,
            displayOption: displayOption
        )
        onStateChange?(self.activeSession)
        return true
    }

    func endSession() {
        clearCurrentSession()
    }

    private func clearCurrentSession() {
        expirationTimer?.cancel()
        expirationTimer = nil

        if activeSession != nil {
            assertionController.deactivate()
            activeSession = nil
            onStateChange?(activeSession)
        }
    }
}
