import Foundation
import IOKit.pwr_mgt

enum PowerAssertionType: Equatable {
    case preventIdleSleep
    case preventDisplaySleep

    var ioKitAssertionType: String {
        switch self {
        case .preventIdleSleep:
            return kIOPMAssertionTypeNoIdleSleep
        case .preventDisplaySleep:
            return kIOPMAssertionTypeNoDisplaySleep
        }
    }
}

protocol PowerAssertionClient {
    func createAssertion(type: PowerAssertionType, name: String) -> IOPMAssertionID
    func releaseAssertion(id: IOPMAssertionID)
}

struct SystemPowerAssertionClient: PowerAssertionClient {
    func createAssertion(type: PowerAssertionType, name: String) -> IOPMAssertionID {
        var assertionID = IOPMAssertionID(kIOPMNullAssertionID)
        let result = IOPMAssertionCreateWithName(
            type.ioKitAssertionType as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            name as CFString,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            return IOPMAssertionID(kIOPMNullAssertionID)
        }

        return assertionID
    }

    func releaseAssertion(id: IOPMAssertionID) {
        _ = IOPMAssertionRelease(id)
    }
}

final class IOKitAssertionController: AssertionControlling {
    private let client: any PowerAssertionClient
    private let assertionName: String
    private var activeAssertionIDs: [IOPMAssertionID] = []

    init(
        client: any PowerAssertionClient = SystemPowerAssertionClient(),
        assertionName: String = "Arabica"
    ) {
        self.client = client
        self.assertionName = assertionName
    }

    @discardableResult
    func activate(for displayOption: SessionDisplayOption) -> Bool {
        deactivate()

        activeAssertionIDs = Self.assertionTypes(for: displayOption).map {
            client.createAssertion(type: $0, name: assertionName)
        }

        let hasInvalidAssertion = activeAssertionIDs.contains { $0 == IOPMAssertionID(kIOPMNullAssertionID) }
        if hasInvalidAssertion {
            deactivate()
            return false
        }

        return true
    }

    func deactivate() {
        for assertionID in activeAssertionIDs where assertionID != IOPMAssertionID(kIOPMNullAssertionID) {
            client.releaseAssertion(id: assertionID)
        }

        activeAssertionIDs.removeAll(keepingCapacity: true)
    }

    private static func assertionTypes(for displayOption: SessionDisplayOption) -> [PowerAssertionType] {
        switch displayOption {
        case .allowDisplaySleep:
            [.preventIdleSleep]
        case .keepDisplayAwake:
            [.preventIdleSleep, .preventDisplaySleep]
        }
    }
}
