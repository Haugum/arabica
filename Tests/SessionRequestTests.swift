import XCTest
@testable import Arabica

final class SessionRequestTests: XCTestCase {
    func testUntilTimeLaterTodayResolvesToSameDayEndDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 1,
            hour: 10,
            minute: 15
        ).date!

        let endDate = UntilTime(hour: 18, minute: 45).resolvedEndDate(
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(
            endDate,
            DateComponents(
                calendar: calendar,
                year: 2026,
                month: 3,
                day: 1,
                hour: 18,
                minute: 45
            ).date!
        )
    }

    func testUntilTimeEarlierTodayRollsForwardToTomorrow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 1,
            hour: 22,
            minute: 15
        ).date!

        let endDate = UntilTime(hour: 6, minute: 30).resolvedEndDate(
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(
            endDate,
            DateComponents(
                calendar: calendar,
                year: 2026,
                month: 3,
                day: 2,
                hour: 6,
                minute: 30
            ).date!
        )
    }

    func testUntilTimeEqualToCurrentClockTimeRollsForwardToTomorrow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 1,
            hour: 22,
            minute: 15
        ).date!

        let endDate = UntilTime(hour: 22, minute: 15).resolvedEndDate(
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(
            endDate,
            DateComponents(
                calendar: calendar,
                year: 2026,
                month: 3,
                day: 2,
                hour: 22,
                minute: 15
            ).date!
        )
    }

    func testPresetSessionCalculatesEndDateFromStartDate() {
        let startDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let request = SessionRequest(
            duration: .preset(.oneHour),
            displayOption: .allowDisplaySleep
        )

        let session = request.activate(at: startDate)

        XCTAssertEqual(session.startedAt, startDate)
        XCTAssertEqual(session.endsAt, startDate.addingTimeInterval(60 * 60))
        XCTAssertEqual(session.displayOption, .allowDisplaySleep)
    }

    func testUntilSessionUsesProvidedEndDate() {
        let startDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let endDate = Date(timeIntervalSinceReferenceDate: 5_000)
        let request = SessionRequest(
            duration: .until(endDate),
            displayOption: .keepDisplayAwake
        )

        let session = request.activate(at: startDate)

        XCTAssertEqual(session.endsAt, endDate)
        XCTAssertEqual(session.displayOption, .keepDisplayAwake)
    }

    func testIndefiniteSessionHasNoEndDate() {
        let startDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let request = SessionRequest(
            duration: .indefinite,
            displayOption: .allowDisplaySleep
        )

        let session = request.activate(at: startDate)

        XCTAssertNil(session.endsAt)
        XCTAssertFalse(session.hasExpired(at: startDate.addingTimeInterval(24 * 60 * 60)))
    }
}
