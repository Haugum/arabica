import AppKit
import Darwin
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var runtime: AppRuntime?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let runtime = AppRuntime()
        runtime.start()
        self.runtime = runtime

        #if DEBUG
        if let seconds = ProcessInfo.processInfo.environment["ARABICA_AUTO_QUIT_AFTER"],
           let delay = TimeInterval(seconds),
           delay > 0
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSApp.terminate(nil)
            }
        }
        #endif
    }
}

final class SingleInstanceGuard {
    private var lockFileDescriptor: CInt = -1

    func acquire() -> Bool {
        let lockURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(lockFileName)
        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)

        guard descriptor >= 0 else {
            return true
        }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            return false
        }

        lockFileDescriptor = descriptor
        return true
    }

    private var lockFileName: String {
        let identifier = Bundle.main.bundleIdentifier ?? "Arabica"
        return "\(identifier).lock"
    }

    deinit {
        guard lockFileDescriptor >= 0 else {
            return
        }

        flock(lockFileDescriptor, LOCK_UN)
        close(lockFileDescriptor)
    }
}

@main
struct ArabicaApp {
    static func main() {
        let singleInstanceGuard = SingleInstanceGuard()
        guard singleInstanceGuard.acquire() else {
            return
        }

        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
