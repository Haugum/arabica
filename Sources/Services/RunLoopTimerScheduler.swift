import Foundation

final class RunLoopTimerScheduler: TimerScheduling {
    func schedule(at date: Date, _ action: @escaping () -> Void) -> TimerCancellation {
        let target = TimerActionTarget(action: action)
        let timer = Timer(
            fireAt: date,
            interval: 0,
            target: target,
            selector: #selector(TimerActionTarget.fire),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(timer, forMode: .common)

        return RunLoopTimerCancellation(timer: timer, target: target)
    }
}

private final class RunLoopTimerCancellation: TimerCancellation {
    private weak var timer: Timer?
    private var target: TimerActionTarget?

    init(timer: Timer, target: TimerActionTarget) {
        self.timer = timer
        self.target = target
    }

    func cancel() {
        timer?.invalidate()
        target = nil
    }
}

private final class TimerActionTarget: NSObject {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    @objc
    func fire() {
        action()
    }
}
