import IOKit.ps
import XCTest
@testable import Arabica

final class IOKitPowerSourceSnapshotReaderTests: XCTestCase {
    private let reader = IOKitPowerSourceSnapshotReader()

    func testACProviderReturnsACSnapshot() {
        XCTAssertEqual(
            reader.snapshot(
                providerType: kIOPSACPowerValue,
                sourceDescriptions: [[
                    kIOPSCurrentCapacityKey as String: 20,
                    kIOPSMaxCapacityKey as String: 100,
                ]]
            ),
            .ac
        )
    }

    func testBatterySourceReturnsRoundedPercentRemaining() {
        XCTAssertEqual(
            reader.snapshot(
                providerType: nil,
                sourceDescriptions: [[
                    kIOPSCurrentCapacityKey as String: 33,
                    kIOPSMaxCapacityKey as String: 80,
                ]]
            ),
            .battery(percentRemaining: 41)
        )
    }

    func testInvalidBatteryReadingsFallBackToACSnapshot() {
        XCTAssertEqual(
            reader.snapshot(
                providerType: nil,
                sourceDescriptions: [[
                    kIOPSCurrentCapacityKey as String: 33,
                    kIOPSMaxCapacityKey as String: 0,
                ]]
            ),
            .ac
        )
    }
}
