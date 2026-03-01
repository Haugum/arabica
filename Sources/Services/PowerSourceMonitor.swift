import Foundation
import IOKit.ps

struct IOKitPowerSourceSnapshotReader {
    func currentSnapshot() -> PowerSourceSnapshot {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let providerType = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        let sourceDescriptions = (IOPSCopyPowerSourcesList(info).takeRetainedValue() as Array).compactMap {
            IOPSGetPowerSourceDescription(info, $0)?.takeUnretainedValue() as? [String: Any]
        }

        return snapshot(providerType: providerType, sourceDescriptions: sourceDescriptions)
    }

    func snapshot(
        providerType: String?,
        sourceDescriptions: [[String: Any]]
    ) -> PowerSourceSnapshot {
        if providerType == kIOPSACPowerValue {
            return .ac
        }

        for description in sourceDescriptions {
            guard
                let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
                let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int,
                maxCapacity > 0
            else {
                continue
            }

            let percentRemaining = Int((Double(currentCapacity) / Double(maxCapacity) * 100).rounded())
            return .battery(percentRemaining: percentRemaining)
        }

        return .ac
    }
}

@MainActor
final class PowerSourceMonitor {
    var onChange: ((PowerSourceSnapshot) -> Void)?

    private let snapshotReader: IOKitPowerSourceSnapshotReader
    private var runLoopSource: CFRunLoopSource?

    init(snapshotReader: IOKitPowerSourceSnapshotReader = IOKitPowerSourceSnapshotReader()) {
        self.snapshotReader = snapshotReader
    }

    func start() {
        onChange?(snapshotReader.currentSnapshot())

        guard runLoopSource == nil else {
            return
        }

        guard let runLoopSource = IOPSNotificationCreateRunLoopSource(
            { context in
                guard let context else {
                    return
                }

                let monitor = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
                Task { @MainActor in
                    monitor.onChange?(monitor.snapshotReader.currentSnapshot())
                }
            },
            Unmanaged.passUnretained(self).toOpaque()
        )?.takeRetainedValue() else {
            return
        }

        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }
}
