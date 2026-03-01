import Foundation
import XCTest
@testable import Arabica

final class BatteryGuardPolicyTests: XCTestCase {
    func testDisabledThresholdNeverEndsActiveSession() {
        let policy = BatteryGuardPolicy(lowBatteryThreshold: nil)

        XCTAssertEqual(
            policy.action(
                for: .battery(percentRemaining: 10),
                activeSession: makeActiveSession()
            ),
            .keepSession
        )
    }

    func testBatteryBelowThresholdEndsActiveSession() {
        let policy = BatteryGuardPolicy(lowBatteryThreshold: 20)

        XCTAssertEqual(
            policy.action(
                for: .battery(percentRemaining: 19),
                activeSession: makeActiveSession()
            ),
            .endSession
        )
    }

    func testACPowerNeverTriggersAutomaticEnd() {
        let policy = BatteryGuardPolicy(lowBatteryThreshold: 20)

        XCTAssertEqual(
            policy.action(
                for: .ac,
                activeSession: makeActiveSession()
            ),
            .keepSession
        )
    }

    func testBatteryAboveThresholdLeavesActiveSessionRunning() {
        let policy = BatteryGuardPolicy(lowBatteryThreshold: 20)

        XCTAssertEqual(
            policy.action(
                for: .battery(percentRemaining: 55),
                activeSession: makeActiveSession()
            ),
            .keepSession
        )
    }

    private func makeActiveSession() -> ActiveSession {
        ActiveSession(
            startedAt: Date(timeIntervalSinceReferenceDate: 1_000),
            endsAt: Date(timeIntervalSinceReferenceDate: 2_000),
            displayOption: .allowDisplaySleep
        )
    }
}
