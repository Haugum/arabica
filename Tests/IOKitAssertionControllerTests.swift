import IOKit.pwr_mgt
import XCTest
@testable import Arabica

final class IOKitAssertionControllerTests: XCTestCase {
    func testActivatingAllowDisplaySleepCreatesSystemIdleAssertion() {
        let client = FakePowerAssertionClient(createdAssertionIDs: [1])
        let controller = IOKitAssertionController(client: client)

        controller.activate(for: .allowDisplaySleep)

        XCTAssertEqual(client.createdTypes, [.preventIdleSleep])
    }

    func testActivatingKeepDisplayAwakeCreatesSystemAndDisplayAssertions() {
        let client = FakePowerAssertionClient(createdAssertionIDs: [1, 2])
        let controller = IOKitAssertionController(client: client)

        controller.activate(for: .keepDisplayAwake)

        XCTAssertEqual(client.createdTypes, [.preventIdleSleep, .preventDisplaySleep])
    }

    func testDeactivationSkipsNullAssertionIDs() {
        let client = FakePowerAssertionClient(
            createdAssertionIDs: [IOPMAssertionID(kIOPMNullAssertionID), 42]
        )
        let controller = IOKitAssertionController(client: client)

        controller.activate(for: .keepDisplayAwake)
        controller.deactivate()

        XCTAssertEqual(client.releasedAssertionIDs, [42])
    }
}

private final class FakePowerAssertionClient: PowerAssertionClient {
    private let createdAssertionIDs: [IOPMAssertionID]
    private var nextAssertionIndex = 0

    private(set) var createdTypes: [PowerAssertionType] = []
    private(set) var releasedAssertionIDs: [IOPMAssertionID] = []

    init(createdAssertionIDs: [IOPMAssertionID]) {
        self.createdAssertionIDs = createdAssertionIDs
    }

    func createAssertion(type: PowerAssertionType, name: String) -> IOPMAssertionID {
        createdTypes.append(type)
        defer { nextAssertionIndex += 1 }

        guard nextAssertionIndex < createdAssertionIDs.count else {
            XCTFail("Missing fake assertion ID for createAssertion call")
            return IOPMAssertionID(kIOPMNullAssertionID)
        }

        return createdAssertionIDs[nextAssertionIndex]
    }

    func releaseAssertion(id: IOPMAssertionID) {
        releasedAssertionIDs.append(id)
    }
}
