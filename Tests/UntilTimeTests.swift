import Foundation
import XCTest
@testable import Arabica

final class UntilTimeTests: XCTestCase {
    func testSessionRequestFactoryBuildsUntilRequestFromClockTime() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 1,
            hour: 9,
            minute: 0
        ).date!

        let request = SessionRequest.until(
            UntilTime(hour: 11, minute: 45),
            relativeTo: now,
            displayOption: .keepDisplayAwake,
            calendar: calendar
        )

        XCTAssertEqual(
            request,
            SessionRequest(
                duration: .until(
                    DateComponents(
                        calendar: calendar,
                        year: 2026,
                        month: 3,
                        day: 1,
                        hour: 11,
                        minute: 45
                    ).date!
                ),
                displayOption: .keepDisplayAwake
            )
        )
    }
}
