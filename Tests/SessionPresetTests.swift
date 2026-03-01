import XCTest
@testable import Arabica

final class SessionPresetTests: XCTestCase {
    func testThirtyMinutesHasExpectedDuration() {
        XCTAssertEqual(SessionPreset.thirtyMinutes.duration, 30 * 60)
    }
}
